# frozen_string_literal: true

class CatalogController < ApplicationController
  include Blacklight::Catalog
  include Arclight::Catalog
  include Arclight::FieldConfigHelpers
  include BlacklightRangeLimit::ControllerOverride

  # This should be unnecessary with an update ArcLight or Blacklight upstream
  def raw
    raise(ActionController::RoutingError, "Not Found") unless blacklight_config.raw_endpoint.enabled

    _, @document = search_service.fetch(params[:id])
    render json: @document.as_json
  end

  # @see Blacklight::Catalog#show
  def show
    deprecated_response, @document = search_service.fetch(params[:id])
    @response = ActiveSupport::Deprecation::DeprecatedObjectProxy.new(deprecated_response, "The @response instance variable is deprecated; use @document.response instead.")

    # If the item can be requested, construct the request
    @aeon_external_request = (helpers.aeon_external_request_class.new(@document, helpers.show_presenter(@document)) if item_requestable?)

    respond_to do |format|
      format.html do
        if request.xml_http_request?.nil?
          @search_context = setup_next_and_previous_documents
        else
          # If a component (rather than an entire collection) is requested, this ensures that the component has no child nodes
          minimal_attributes = @document.attributes
          minimal_attributes["components"] = [] unless @document.collection?

          render "catalog/_minimal", locals: { attributes: minimal_attributes }
        end
      end
      format.json do
        render json: @document.to_json
      end
      additional_export_formats(@document, format)
    end
  end

  def index
    query_param = params[:q]
    return super unless /^(aspace_)?[A-Z]{1,2}\d{3,4}([.-].*)?(_c.*)?$/.match?(query_param)

    # Try and take the user directly to the show page
    server_response = Blacklight.default_index.connection.get("select", params: { q: "id:#{query_param.tr('.', '-')}" })
    solr_response = server_response["response"]
    docs = solr_response["docs"]
    return super if docs.empty?

    @document = SolrDocument.new(docs.first)
    redirect_to solr_document_path(id: @document)
  end

  # This overrides Arclight::FieldConfigHelpers#item_requestable?
  def item_requestable?(_ = nil, _options = {})
    @document.present? && @document.repository_config.present?
  end

  configure_blacklight do |config|
    ## Class for sending and receiving requests from a search index
    # config.repository_class = Blacklight::Solr::Repository
    #
    ## Class for converting Blacklight's url parameters to into request parameters for the search index
    # config.search_builder_class = ::SearchBuilder
    #
    ## Model that maps search index responses to the blacklight response model
    # config.response_model = Blacklight::Solr::Response

    config.raw_endpoint.enabled = true

    ## Default parameters to send to solr for all search-like requests. See also SearchBuilder#processed_parameters
    config.default_solr_params = {
      rows: 10
    }

    # solr path which will be added to solr base url before the other solr params.
    # config.solr_path = 'select'

    # items to show per page, each number in the array represent another option to choose from.
    # config.per_page = [10,20,50,100]

    ## Default parameters to send on single-document requests to Solr. These settings are the Blacklight defaults (see SearchHelper#solr_doc_params) or
    ## parameters included in the Blacklight-jetty document requestHandler.
    #
    # config.default_document_solr_params = {
    #  qt: 'document',
    #  ## These are hard-coded in the blacklight 'document' requestHandler
    #  # fl: '*',
    #  # rows: 1,
    #  # q: '{!term f=id v=$id}'
    # }

    config.default_document_solr_params = {
      fl: "*,[child]"
    }

    # solr field configuration for search results/index views
    config.index.title_field = "normalized_title_ssm"
    config.index.display_type_field = "level_ssm"
    # config.index.thumbnail_field = 'thumbnail_path_ss'

    # solr field configuration for document/show views
    # config.show.title_field = 'title_display'
    config.show.display_type_field = "level_ssm"
    # config.show.thumbnail_field = 'thumbnail_path_ss'

    config.add_results_document_tool(:bookmark, partial: "bookmark_control", if: :render_bookmarks_control?)

    config.add_results_collection_tool(:sort_widget)
    config.add_results_collection_tool(:per_page_widget)
    config.add_results_collection_tool(:view_type_group)

    config.add_show_tools_partial(:bookmark, partial: "bookmark_control", if: :render_bookmarks_control?)
    config.add_show_tools_partial(:email, callback: :email_action, validator: :validate_email_params)
    config.add_show_tools_partial(:sms, if: :render_sms_action?, callback: :sms_action, validator: :validate_sms_params)
    config.add_show_tools_partial(:citation)

    config.add_nav_action(:bookmark, partial: "blacklight/nav/bookmark", if: :render_bookmarks_control?)
    config.add_nav_action(:search_history, partial: "blacklight/nav/search_history")

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    #
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _displayed_ in a page.
    # * If set to 'true', then no additional parameters will be sent to solr,
    # but any 'sniffed' request limit parameters will be used for paging, with
    # paging at requested limit -1. Can sniff from facet.limit or
    # f.specific_field.facet.limit solr request params. This 'true' config
    # can be used if you set limits in :default_solr_params, or as defaults
    # on the solr side in the request handler itself. Request handler defaults
    # sniffing requires solr requests to be made with "echoParams=all", for
    # app code to actually have it echo'd back to see it.
    #
    # :show may be set to false if you don't want the facet to be drawn in the
    # facet bar
    #
    # set :index_range to true if you want the facet pagination view to have facet prefix-based navigation
    #  (useful when user clicks "more" on a large facet and wants to navigate alphabetically across a large set of results)
    # :index_range can be an array or range of prefixes that will be used to create the navigation (note: It is case sensitive when searching values)

    config.add_facet_field "has_online_content_ssim", label: "Access", collapse: false, query: {
      offline: { label: "In the Library", fq: "has_online_content_ssim:false" },
      online: { label: "Online", fq: "has_online_content_ssim:true" }
    }
    config.add_facet_field "collection_sim", label: "Collection", limit: 10
    config.add_facet_field "creator_ssim", label: "Creator", limit: 10
    config.add_facet_field "creators_ssim", label: "Creator", show: false
    config.add_facet_field "date_range_sim", label: "Date range", range: true
    config.add_facet_field "names_ssim", label: "Names", limit: 10
    config.add_facet_field "repository_sim", label: "Repository", limit: 10
    config.add_facet_field "geogname_sim", label: "Place", limit: 10
    config.add_facet_field "places_ssim", label: "Places", show: false
    config.add_facet_field "access_subjects_ssim", label: "Subject", limit: 10

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    config.add_index_field "unitid_ssm", label: "Unit ID"
    config.add_index_field "repository_ssm", label: "Repository"
    config.add_index_field "normalized_date_ssm", label: "Date"
    config.add_index_field "creator_ssm", label: "Creator"
    config.add_index_field "language_ssm", label: "Language"
    config.add_index_field "scopecontent_ssm", label: "Scope Content"
    config.add_index_field "extent_ssm", label: "Physical Description"
    config.add_index_field "accessrestrict_ssm", label: "Conditions Governing Access"
    config.add_index_field "collection_ssm", label: "Collection Title"
    config.add_index_field "geogname_ssm", label: "Place"

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different.

    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise.
    config.add_search_field "all_fields", label: "All Fields" do |field|
      field.include_in_simple_select = true
    end

    config.add_search_field "within_collection" do |field|
      field.include_in_simple_select = false
      field.solr_parameters = {
        fq: "-level_sim:Collection"
      }
    end

    # Field-based searches. We have registered handlers in the Solr configuration
    # so we have Blacklight use the `qt` parameter to invoke them
    config.add_search_field "keyword", label: "Keyword" do |field|
      field.qt = "search" # default
    end
    config.add_search_field "name", label: "Name" do |field|
      field.qt = "search"
      field.solr_parameters = {
        qf: "${qf_name}",
        pf: "${pf_name}"
      }
    end
    config.add_search_field "place", label: "Place" do |field|
      field.qt = "search"
      field.solr_parameters = {
        qf: "${qf_place}",
        pf: "${pf_place}"
      }
    end
    config.add_search_field "subject", label: "Subject" do |field|
      field.qt = "search"
      field.solr_parameters = {
        qf: "${qf_subject}",
        pf: "${pf_subject}"
      }
    end
    config.add_search_field "title", label: "Title" do |field|
      field.qt = "search"
      field.solr_parameters = {
        qf: "${qf_title}",
        pf: "${pf_title}"
      }
    end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field "score desc, title_sort asc", label: "relevance"
    config.add_sort_field "date_sort asc", label: "date (ascending)"
    config.add_sort_field "date_sort desc", label: "date (descending)"
    config.add_sort_field "creator_sort asc", label: "creator (A-Z)"
    config.add_sort_field "creator_sort desc", label: "creator (Z-A)"
    config.add_sort_field "title_sort asc", label: "title (A-Z)"
    config.add_sort_field "title_sort desc", label: "title (Z-A)"

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5

    # Configuration for autocomplete suggestor
    config.autocomplete_enabled = true
    config.autocomplete_path = "suggest"

    ##
    # Arclight Configurations

    config.show.document_presenter_class = Arclight::ShowPresenter
    config.index.document_presenter_class = Arclight::IndexPresenter

    ##
    # Configuration for partials
    config.index.partials = %i[arclight_index_default]

    ##
    # Configuration for index actions
    config.index.document_actions << :containers
    config.index.document_actions << :online_content_label
    config.add_results_document_tool :arclight_bookmark_control, partial: "arclight_bookmark_control"
    config.index.document_actions.delete(:bookmark)

    config.show.metadata_partials = %i[
      summary_field
      access_field
      collection_description_field
      collection_history_field
      background_field
      related_field
    ]

    config.show.context_access_tab_items = %i[
      terms_field
      cite_field
      in_person_field
      contact_field
    ]

    config.show.component_metadata_partials = %i[
      component_field
    ]

    config.show.component_access_tab_items = %i[
      component_terms_field
      cite_field
      in_person_field
      contact_field
    ]

    # ===========================
    # COLLECTION SHOW PAGE FIELDS
    # ===========================

    # Collection Show Page - Summary Section
    config.add_summary_field "creators_ssim", label: "Creator", link_to_facet: true
    config.add_summary_field "title_ssm", label: "Title"
    config.add_summary_field "repository_ssm", label: "Repository"
    config.add_summary_field "normalized_date_ssm", label: "Dates"
    config.add_summary_field "extent_ssm", label: "Size"
    config.add_summary_field "storage_notes", label: "Storage Note", accessor: :storage_notes
    config.add_summary_field "language_ssm", label: "Language"

    # Collect Show Page - Abstract Section
    config.add_abstract_field "abstract_ssm", label: "Abstract", helper_method: :paragraph_separator

    # ==========================
    # COMPONENT SHOW PAGE FIELDS
    # ==========================

    # Component Show Page - Metadata Section
    config.add_component_field "collection_creator_ssm", label: "Collection Creator"
    config.add_component_field "unitdate_inclusive_ssm", label: "Dates"
    config.add_component_field "physloc_ssm", label: "Located In"
    config.add_component_field "extent_ssm", label: "Extent"
    config.add_component_field "language_ssm", label: "Languages"
    config.add_component_field "parent_access_restrict_ssm", label: "Access Restrictions"
    config.add_component_field "prefercite_ssm", label: "Credit this material", helper_method: :paragraph_separator

    # =================================
    # COLLECTION DESCRIPTION TAB FIELDS
    # =================================
    config.add_collection_description_field "collection_description_ssm", label: "Description", helper_method: :paragraph_separator
    config.add_collection_description_field "arrangement_ssm", label: "Arrangement", helper_method: :paragraph_separator
    config.add_collection_description_field "bioghist_ssm", label: "Collection Creator Biography", helper_method: :paragraph_separator
    config.add_collection_description_field "odd_ssm", label: "Note", helper_method: :paragraph_separator, accessor: :fetch_html_safe

    # =============================
    # COLLECTION HISTORY TAB FIELDS
    # =============================
    config.add_collection_history_field "acqinfo_ssm", label: "Acquisition", helper_method: :paragraph_separator
    config.add_collection_history_field "custodhist_ssm", label: "Custodial History", helper_method: :paragraph_separator
    config.add_collection_history_field "accruals_ssm", label: "Additions", helper_method: :paragraph_separator
    config.add_collection_history_field "appraisal_ssm", label: "Archival Appraisal Information", helper_method: :paragraph_separator
    config.add_collection_history_field "sponsor_ssm", label: "Sponsorship", helper_method: :paragraph_separator
    config.add_collection_history_field "processinfo_processing_ssm", label: "Processing Information", helper_method: :paragraph_separator, accessor: :fetch_html_safe
    config.add_collection_history_field "processinfo_conservation_ssm", label: "Conservation", helper_method: :paragraph_separator, accessor: :fetch_html_safe

    # =================
    # ACCESS TAB FIELDS
    # =================
    config.add_access_field "accessrestrict_ssm", label: "Access Restrictions", helper_method: :paragraph_separator
    config.add_access_field "userestrict_ssm", label: "Conditions for Reproduction and Use", helper_method: :paragraph_separator, accessor: :fetch_html_safe
    config.add_access_field "phystech_ssm", label: "Special Requirements for Access", helper_method: :paragraph_separator, accessor: :fetch_html_safe
    config.add_access_field "otherfindaid_ssm", label: "Other Finding Aids", helper_method: :paragraph_separator, accessor: :fetch_html_safe
    config.add_access_field "prefercite_ssm", label: "Credit this material", helper_method: :paragraph_separator
    config.add_access_field "repository_ssm", if: :repository_config_present, label: "Location", helper_method: :context_access_tab_repository
    # Using ID because we know it will always exist
    config.add_access_field "id", if: :before_you_visit_note_present, label: "Before you visit", helper_method: :context_access_tab_visit_note

    # =================
    # FIND RELATED TAB FIELDS
    # =================
    config.add_indexed_terms_field "altformavail_ssm", label: "Alternative Form Available", helper_method: :paragraph_separator, accessor: :fetch_html_safe
    config.add_indexed_terms_field "relatedmaterial_ssm", label: "Related Material", helper_method: :paragraph_separator, accessor: :fetch_html_safe
    config.add_indexed_terms_field "originalsloc_ssm", label: "Location of Originals", helper_method: :paragraph_separator, accessor: :fetch_html_safe
    config.add_indexed_terms_field "separatedmaterial_ssm", label: "Separated Material", helper_method: :paragraph_separator, accessor: :fetch_html_safe
    config.add_indexed_terms_field "bibliography_ssm", label: "Publication Note", helper_method: :paragraph_separator, accessor: :fetch_html_safe
    config.add_indexed_terms_field "topics_ssim", label: "Topics", link_to_facet: true, separator_options: {
      words_connector: "<br/>",
      two_words_connector: "<br/>",
      last_word_connector: "<br/>"
    }

    config.add_indexed_terms_field "subject_terms_ssim", label: "Subject Terms", link_to_facet: true, separator_options: {
      words_connector: "<br/>",
      two_words_connector: "<br/>",
      last_word_connector: "<br/>"
    }

    config.add_indexed_terms_field "genreform_ssim", label: "Genre Terms", link_to_facet: true, separator_options: {
      words_connector: "<br/>",
      two_words_connector: "<br/>",
      last_word_connector: "<br/>"
    }

    config.add_indexed_terms_field "names_coll_ssim", label: "Names", separator_options: {
      words_connector: "<br/>",
      two_words_connector: "<br/>",
      last_word_connector: "<br/>"
    }, helper_method: :link_to_name_facet

    config.add_indexed_terms_field "places_ssim", label: "Places", link_to_facet: true, separator_options: {
      words_connector: "<br/>",
      two_words_connector: "<br/>",
      last_word_connector: "<br/>"
    }

    # Remove unused show document actions
    %i[citation email sms].each do |action|
      config.view_config(:show).document_actions.delete(action)
    end

    # Insert the breadcrumbs at the beginning
    config.show.partials.unshift(:show_collection_header)
    config.show.partials.delete(:show_header)

    ##
    # Hierarchy Index View
    config.view.hierarchy
    config.view.hierarchy.display_control = false
    config.view.hierarchy.partials = %i[index_header_hierarchy index_hierarchy]

    ##
    # Hierarchy Index View
    config.view.online_contents
    config.view.online_contents.display_control = false
    config.view.online_contents.partials = config.view.hierarchy.partials.dup

    ##
    # Collection Context
    config.view.collection_context
    config.view.collection_context.display_control = false
    config.view.collection_context.partials = %i[index_collection_context]

    ##
    # Compact index view
    config.view.compact
    config.view.compact.partials = %i[arclight_index_compact]
  end
end

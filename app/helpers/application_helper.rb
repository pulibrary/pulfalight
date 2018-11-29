module ApplicationHelper

  def repository_thumbnail(repository)
    image_tag repository_thumbnail_url(repository), alt: repository.name, class: 'img-fluid'
  end

  private

    def repository_thumbnail_url(repository)
      return repository.thumbnail_url unless repository.thumbnail_url.blank?

      logo_path
    end

    def logo_path
      'logo.png'
    end
end

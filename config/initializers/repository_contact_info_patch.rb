# frozen_string_literal: true
module RepositoryContactInfoPatch
  def contact_info
    super.html_safe
  end
end
Arclight::Repository.prepend(RepositoryContactInfoPatch)

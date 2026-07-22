class DocsController < ApplicationController
  def index
    @doc_pages = DocPage.ordered
    @doc_pages_by_category = @doc_pages.group_by(&:category)
  end

  def show
    @doc_page = DocPage.find_by!(slug: params[:slug])
    @related_pages = DocPage.where.not(id: @doc_page.id).ordered.limit(4)
  end
end

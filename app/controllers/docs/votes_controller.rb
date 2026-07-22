module Docs
  class VotesController < ApplicationController
    def create
      @doc_page = DocPage.find_by!(slug: params[:doc_slug])

      case params[:direction]
      when "up"
        @doc_page.increment!(:upvotes)
      when "down"
        @doc_page.increment!(:downvotes)
      else
        return render json: { error: "direction must be up or down" }, status: :unprocessable_entity
      end

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to doc_path(@doc_page), notice: "Thanks for the feedback." }
        format.json { render json: { upvotes: @doc_page.upvotes, downvotes: @doc_page.downvotes, score: @doc_page.score } }
      end
    end
  end
end

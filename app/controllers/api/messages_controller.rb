module Api
  class MessagesController < ApplicationController
    protect_from_forgery with: :null_session

    def index
      render json: Message.order(created_at: :desc).limit(20).reverse.map { |message| serialize(message) }
    end

    def create
      message = Message.create!(message_params)
      render json: serialize(message), status: :created
    rescue ActionController::ParameterMissing, ActiveRecord::RecordInvalid => error
      render json: { error: error.message }, status: :unprocessable_entity
    end

    private
      def message_params
        params.require(:message).permit(:author, :body)
      end

      def serialize(message)
        {
          id: message.id,
          author: message.author,
          body: message.body,
          created_at: message.created_at.iso8601
        }
      end
  end
end

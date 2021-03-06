module Mailkick
  class SubscriptionsController < ActionController::Base
    before_filter :set_email

    def show
    end

    def unsubscribe
      Mailkick.opt_out(@options)
      redirect_to subscription_path(url_token)
    end

    def subscribe
      Mailkick.opt_in(@options)
      redirect_to subscription_path(url_token)
    end

    protected

    def set_email
      verifier = ActiveSupport::MessageVerifier.new(Mailkick.secret_token)
      begin
        # email must be base64 encoded, e.g., for '+' character, or MessageVerifier barfs
        encoded_email, user_id, user_type, @list = verifier.verify(params[:id])
        @email = Base64.decode64(encoded_email)

        # if user_type
        #   # on the unprobabilistic chance user_type is compromised, not much damage
        #   @user = user_type.constantize.find(user_id)
        # end
        # @options = {
        #     email: @email,
        #     user: @user,
        #     list: @list
        # }
        
        @user = nil
        if user_type && user_id
          # on the unprobabilistic chance user_type is compromised, not much damage
          @user = user_type.constantize.find(user_id)
        end
        @options = {
          email: @email,
          user: @user,
          list: @list
        }
      rescue ActiveSupport::MessageVerifier::InvalidSignature
        render text: "Subscription not found", status: :bad_request
      end
    end

    def opted_out?
      Mailkick.opted_out?(@options)
    end
    helper_method :opted_out?

    def subscribe_url
      subscribe_subscription_path(url_token)
    end
    helper_method :subscribe_url

    def unsubscribe_url
      unsubscribe_subscription_path(url_token)
    end
    helper_method :unsubscribe_url

    private

    def url_token
      @url_token ||= CGI.escape(params[:id])
    end
  end
end

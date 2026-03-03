# This is a monkey patch to allow us to use impersonated service account credentials for local development with govuk-docker
# https://github.com/googleapis/google-auth-library-ruby/issues/563
module Google
  module Auth
    class ImpersonatedServiceAccountCredentials
    private

      def prepare_auth_header
        @source_credentials.updater_proc.call({})
      end
    end
  end
end

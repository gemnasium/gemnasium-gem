module Gemnasium
  class InvalidApiKeyError < StandardError
    def message
      'Your API key is invalid. Please double check it on https://gemnasium.com/settings/api_access'
    end
  end
  class DeprecatedApiVersionError < StandardError; end
  class MalformedRequestError < StandardError; end
  class MissingParamsError < StandardError; end
  class NonBillableUserError < StandardError; end
  class NoSlotsAvailableError < StandardError; end
  class ProjectNotFoundError < StandardError; end
  class ProjectNotOfflineError < StandardError; end
  class ProjectParamMissingError < StandardError; end
  class UnsupportedDependencyFilesError < StandardError; end
end

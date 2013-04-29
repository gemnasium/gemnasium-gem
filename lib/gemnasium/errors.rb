module Gemnasium
  class InvalidApiKeyError < StandardError
    def message
      'Your API key is invalid. Please double check it on https://gemnasium.com/settings/api_access'
    end
  end
  class DeprecatedApiVersionError < StandardError; end
  # Profile errors
  class ProfileNotFoundError < StandardError; end
  class ProfileNotOwnedError < StandardError; end
  class NoSlotsAvailableError < StandardError; end
  # Project errors
  class ProjectNotFoundError < StandardError; end
  class ProjectNotCreatedError < StandardError; end
  class ProjectParamMissingError < StandardError; end
  class ProjectAlreadyExistsError < StandardError; end
  class ProjectGithubSyncedError < StandardError; end
  class ProjectBranchMismatchError < StandardError; end
  class ProjectIsPublicError < StandardError; end
end

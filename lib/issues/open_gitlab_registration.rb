module Intrigue
  module Issue
  class OpenGitlabRegistration < BaseIssue
  
    def self.generate(instance_details={})
      to_return = {
        name: "open_gitlab_registration",
        pretty_name: "Open Gitlab Registration",
        severity: 2,
        status: "confirmed",
        category: "application",
        description: "This server allows anonymous users to register.",
        remediation: "Verify that anonymous users should be able to register on this server.",
        references: [
          { type: "description", uri: "https://gitlab.com/gitlab-org/gitlab-foss/issues/66124"},
          { type: "remediation", uri: "https://computingforgeeks.com/how-to-disable-user-creation-signup-on-gitlab-welcome-page/"}
        ]
      }.merge!(instance_details)
  
    to_return
    end
  
  end
  end
  end
  
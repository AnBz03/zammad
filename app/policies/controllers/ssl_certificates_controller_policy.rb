# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Controllers::SSLCertificatesControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.security')
end

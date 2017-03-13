class ApplicationMailer < ActionMailer::Base
  default from: 'info@easy-ts.ru',
          template_path: 'mailers'
end

# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: "notificaciones@martinalawyer.co"
  layout "mailer"
end

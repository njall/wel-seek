require "action_mailer"
require "exception_notifiable"
require "exception_notifier"
require "exception_notifier_helper"

Object.class_eval do include Notifiable end

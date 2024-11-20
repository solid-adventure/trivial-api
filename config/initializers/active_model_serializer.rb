ActiveModelSerializers.config.adapter = :json

# Disable noisy serializer logging
require 'active_model_serializers'
ActiveSupport::Notifications.unsubscribe(ActiveModelSerializers::Logging::RENDER_EVENT)
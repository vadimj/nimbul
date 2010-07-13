#
# Add your destination definitions here
# can also be used to configure filters, and processor groups
#
ActiveMessaging::Gateway.define do |s|
### Nimbul Receives From:
  s.destination :startup,  'startup',  :exchange_type => :topic
  s.destination :shutdown, 'shutdown', :exchange_type => :topic
  s.destination :info,     'info',     :exchange_type => :topic
  
  # Node -> Nimbul response queue
  s.destination :response, 'nimbul',   :exchange_type => :direct

### Nimbul Publishes to:

  # Request is for publishing only  
  s.destination :request,  'request',  :exchange_type => :topic

  # Nimbul -> Nimbul control queue
  s.destination :myself,   'control',   :exchange_type => :direct

  # Nimbul -> AMQP Server command queue
  s.destination :rabbitmq,  'rabbitmq',  :exchange_type => :direct
end

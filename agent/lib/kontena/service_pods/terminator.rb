require 'docker'
require_relative 'common'
require_relative '../logging'

module Kontena
  module ServicePods
    class Terminator
      include Kontena::Logging
      include Common

      attr_reader :service_pod

      # @param [ServicePod] service_pod
      # @param [Hash] opts
      def initialize(service_pod)
        @service_pod = service_pod
      end

      # @return [Docker::Container]
      def perform
        service_container = get_container(service_pod.service_id, service_pod.instance_number)
        if service_container
          info "terminating service: #{service_container.name_for_humans}"
          log_service_pod_event(
            service_pod.service_id, service_pod.instance_number,
            "service:remove_instance", "removing service instance #{service_container.name_for_humans}"
          )
          service_container.stop('timeout' => service_container.stop_grace_period)
          service_container.wait
          service_container.delete(v: true)

          log_service_pod_event(
            service_pod.service_id, service_pod.instance_number,
            "service:remove_instance", "service instance #{service_container.name_for_humans} removed successfully"
          )
        end
        data_container = get_container(service_pod.service_id, service_pod.instance_number, 'volume')
        if data_container
          info "cleaning up service volumes: #{data_container.name}"
          log_service_pod_event(
            service_pod.service_id, service_pod.instance_number,
            "service:remove_instance", "removing service instance #{service_container.name_for_humans} data volume"
          ) if service_container

          data_container.delete(v: true)

          log_service_pod_event(
            service_pod.service_id, service_pod.instance_number,
            "service:remove_instance", "service instance #{service_container.name_for_humans} data volume removed succesfully"
          ) if service_container
        end

        service_container
      end
    end
  end
end

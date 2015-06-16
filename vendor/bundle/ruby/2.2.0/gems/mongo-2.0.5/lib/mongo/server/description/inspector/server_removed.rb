# Copyright (C) 2014-2015 MongoDB, Inc.
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Mongo
  class Server
    class Description
      class Inspector

        # Handles inspecting the result of an ismaster command for servers
        # that were removed from the cluster.
        #
        # @since 2.0.0
        class ServerRemoved
          include Event::Publisher

          # Instantiate the server removed inspection.
          #
          # @example Instantiate the inspection.
          #   ServerRemoved.new(listeners)
          #
          # @param [ Event::Listeners ] event_listeners The event listeners.
          #
          # @since 2.0.0
          def initialize(event_listeners)
            @event_listeners = event_listeners
          end

          # Run the server added inspection.
          #
          # @example Run the inspection.
          #   ServerAdded.run(description, {})
          #
          # @param [ Description ] description The server description.
          # @param [ Description ] updated The updated description.
          #
          # @since 2.0.0
          def run(description, updated)
            description.hosts.each do |host|
              if updated.primary? && !updated.hosts.include?(host)
                publish(Event::SERVER_REMOVED, host)
              end
            end
          end
        end
      end
    end
  end
end

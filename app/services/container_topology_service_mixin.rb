module ContainerTopologyServiceMixin
  def entity_display_type(entity)
    if entity.kind_of?(ManageIQ::Providers::ContainerManager)
      entity.class.short_token
    elsif entity.kind_of?(ContainerGroup)
      "Pod"
    else
      name = entity.class.name.demodulize
      if name.start_with? "Container"
        if name.length > "Container".length # container related entities such as ContainerService
          name["Container".length..-1]
        else
          "Container" # the container entity itself
        end
      else
        if entity.kind_of?(Vm)
          name.upcase # turn Vm to VM because it's an abbreviation
        else
          name # non container entities such as Host
        end
      end
    end
  end

  def build_entity_data(entity)
    data = build_base_entity_data(entity)
    data.merge!(:status       => entity_status(entity),
                :display_kind => entity_display_type(entity))

    if (entity.kind_of?(Host) || entity.kind_of?(Vm)) && entity.ext_management_system.present?
      data.merge!(:provider => entity.ext_management_system.name)
    end

    data
  end

  def entity_status(entity)
    if entity.kind_of?(Host) || entity.kind_of?(Vm)
      status = entity.power_state.capitalize
    elsif entity.kind_of?(ContainerNode)
      node_ready_status = entity.container_conditions.find_by_name('Ready').try(:status)
      status = case node_ready_status
                 when 'True'
                   'Ready'
                 when 'False'
                   'NotReady'
                 else
                   'Unknown'
               end
    elsif entity.kind_of?(ContainerGroup)
      status = entity.phase
    elsif entity.kind_of?(Container)
      status = entity.state.capitalize
    elsif entity.kind_of?(ContainerReplicator)
      status = (entity.current_replicas == entity.replicas) ? 'OK' : 'Warning'
    elsif entity.kind_of?(ManageIQ::Providers::ContainerManager)
      status = entity.authentications.empty? ? 'Unknown' : entity.default_authentication.status.capitalize
    else
      status = 'Unknown'
    end
    status
  end
end

module InstanceKindsHelper
  def instance_kind_ram(instance_kind)
    return '' if instance_kind.nil?
    return 'N/A' if instance_kind.ram_mb.nil?
    gb = instance_kind.ram_gb
    return "#{gb} GB" if gb > 1.to_f
    return "#{instance_kind.ram_mb} MB"
  end
end

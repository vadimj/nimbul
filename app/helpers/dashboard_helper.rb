module DashboardHelper
    def dashboard_link(o)
        it = image_tag "#{o.label.to_s.singularize}.png", {:class => 'control-icon'}
        lt = link_to o.label.to_s.humanize.titleize.gsub('Provider ','').gsub('Cloud ',''),
            send(o.label.to_s+'_path'),
            { :class => 'dashboard-link' }
        lt = content_tag :strong, lt
        nt = content_tag :strong, o.label.to_s.humanize.titleize.gsub('Provider ','').gsub('Cloud ','')
        ct = o.value
        it+lt+'&nbsp;'+ct.to_s
    end
end

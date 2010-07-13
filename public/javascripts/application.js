// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
function select_parent_element(el) {
    if (el.checked) {
        id = el.up('.selectable');
        if (id != null)
            id.className = id.className.replace(/selectable/,'selected');
    } else {
        id = el.up('.selected');
        if (id != null)
            id.className = id.className.replace(/selected/,'selectable');
    }
}

function reset_selectable_elements(klass) {
    klass = klass || '.selected';
    $$(klass).each(function(el) {
        el.className = el.className.replace(/selected/,'selectable');
    })
}

function mark_for_destroy(el, hide_el) {
    $(el).next('.should_destroy').value = 1;
    if (hide_el != null) $(hide_el).hide();
}

var Selectable = Class.create({});

// Selectable class methods
Object.extend(Selectable, {
    mark_to_enable: function(el) {
        id = $(el).down('.is_enabled');
        if (id != null) id.value = 1;
    },
    mark_to_disable: function(el) {
        id = $(el).down('.is_enabled');
        if (id != null) id.value = 0;
    },
    mark_to_destroy: function(el) {
        id = $(el).down('.should_destroy');
        if (id != null) id.value = 1;
    },
    check: function(el) {
        el.checked = true;
        select_parent_element(el);
    },
    uncheck: function(el) {
        el.checked = false;
        select_parent_element(el);
    },
    enable_selected: function(klass) {
        klass = klass || '.selected';
        $$(klass).each(Selectable.mark_to_enable);
    },
    disable_selected: function(klass) {
        klass = klass || '.selected';
        $$(klass).each(Selectable.mark_to_disable);
    },
    destroy_selected: function(klass) {
        klass = klass || '.selected';
        $$(klass).each(Selectable.mark_to_destroy);
    },
    check_all: function(klass) {
        klass = klass || '.selectable_check_box';
        $$(klass).each(Selectable.check);
    },
    uncheck_all: function(klass) {
        klass = klass || '.selectable_check_box';
        $$(klass).each(Selectable.uncheck);
    },
});

var EditableSelect = Class.create({})

// EditableSelect class methods
Object.extend(EditableSelect, {
	create: function(element) {
		element.editable({
			editField: {
				'type': 'select',
    			'options': [["black", "1"], ["gray", "2"], ["white", "3"]],
    			'foreignKey': true
  			}
		});
	},
	setupAll: function(klass) {
		klass = klass || '.editable_select';
		$$(klass).each(EditableSelect.create);
	}
});

var Loading = Class.create({})

Object.extend(Loading, {
    setup: function() {
	    $('loading').hide();
	    $('error_redbox').hide();
	    $('notice_redbox').hide();
	    $('tiny_redbox').hide();
	    $('small_redbox').hide();
	    $('large_redbox').hide();

        //This is used to tell, everytime an AJAX function is created and completed, the following will get executed.
        Ajax.Responders.register({
            onCreate: function() {
//                new Effect.Opacity('page', { from: 1.0, to: 0.3, duration: 0.5 });
                new Effect.toggle('loading', 'appear');
            },
            onComplete: function() {
                $('loading').hide();
//                new Effect.Opacity('page', { from: 0.3, to: 1, duration: 0.5 });
            },
        });
    },
});

function enterKeyPressed(e) {
	var key;

	if (window.event)
		key = window.event.keyCode;     //IE
	else
		key = e.which;     //firefox

	if (key == 13)
		return true;
	else
        return false;
}

function disableEnterKey(e) {
    return !enterKeyPressed(e);
}

function click_create_snapshot(el, suffix) {
	suffix = suffix || "";
    var msg = "Please specify name suffix for new snapshots.\n\n";
    msg += "Snapshot names will be assigned as follows:\n";
    msg += "<Snapshot Name> = <Volume Name> + <Name Suffix>\n";
    var response = prompt(msg, suffix);
    if (response == null) {
        return false;
    } else {
        $(el).next(".command").value = "snapshot";
        $(el).next(".command_parameter").value = response;
        return true;
    }
}

function click_create_volume(el, zone_el, prefix) {
	zone = zone_el.value;
    prefix = prefix || "";
	if (zone == null || zone.length == 0) {
		alert("Please choose which zone to restore snapshots in");
		zone_el.focus();
		return false;
	}
	var msg = "Creating new Volumes in Availability Zone "+zone+"\n\n";
	msg += "Specify Name Prefix for new Volumes\n\n";
	msg += "Volume Names will be assigned as follows:\n";
	msg += "<Volume Name> =  <Name Prefix> + <Snapshot Name>\n";
	var response = prompt(msg, prefix);
	if (response == null) {
	    return false;
	} else {
	    $(el).next(".command").value = "restore";
	    $(el).next(".command_parameter").value = response;
	    return true;
	}
}

function confirm_delete_cluster() {
    var msg1 = "Are you sure?\n\nAll metadata associated with this Cluster will be deleted.\n\n";
    msg1 += "This includes all Servers, Startup Scripts and Security metadata.\n\n";
    msg1 += "This cannot be undone.\n";
    var msg2 = "Type yes to confirm that you want to delete this Cluster:";
    if (confirm(msg1)) {
        var answer = prompt(msg2);
        return (answer == "yes");
    }
    return false;
}

function confirm_delete_hostname(name) {
    var msg1 = "Are you sure?\n\nAll Leases associated with this Hostname will be deleted.\n\n";
    msg1 += "This cannot be undone.\n";
    var msg2 = "Type yes to confirm that you want to delete Hostname '" + name + "' :";
    if (confirm(msg1)) {
        var answer = prompt(msg2);
        return (answer == "yes");
    }
    return false;
}

function confirm_delete_auto_scaling_group(name) {
    var msg1 = "Are you sure?\n\nAll Auto Scaling Triggers associated with this Group will be deleted.\n\n";
    msg1 += "This cannot be undone.\n";
    var msg2 = "Type yes to confirm that you want to delete Auto Scaling Group '" + name + "' :";
    if (confirm(msg1)) {
        var answer = prompt(msg2);
        return (answer == "yes");
    }
    return false;
}

function confirm_delete_launch_configuration(name) {
    var msg1 = "Are you sure? This cannot be undone.\n";
    var msg2 = "Type yes to confirm that you want to delete Launch Configuration '" + name + "' :";
    if (confirm(msg1)) {
        var answer = prompt(msg2);
        return (answer == "yes");
    }
    return false;
}

function confirm_task_run(message) {
    var msg1 = message + "\n\nAre you sure you want to run this task?\n\n";
    msg1 += "Please think about this before continuing.\n";
    var msg2 = "Type yes to confirm that you want to run this task:";
    if (confirm(msg1)) {
        var answer = prompt(msg2);
        return (answer == "yes");
    }
    return false;
}

function setup_tooltip_titles() {
	// Find all title attributes and create tooltip popups for them
	$$('*').findAll(
		function(node) { return node.getAttribute('title'); }
	).each(
		function(node) { new Tooltip(node, node.title, { default_css: true }); node.removeAttribute('title'); }
	);
}

function unanchored_location() {
	return location.protocol + '//' + location.host + location.pathname
}

function reload_hostname_leases(options) {
	hostname = $(hostname_id = 'hostname_' + options.hostname_id);
	leases = $(lease_id = hostname_id + '_leases');

	timeout_delay = options.delay || 3;
	pulse_duration = Math.ceil(Math.sqrt(timeout_delay)) + timeout_delay;
	pulses = (Math.ceil(pulse_duration / 2) + 1)

	parameters = "authenticity_token=" + encodeURIComponent(options.auth_token);
	if (options.method && options.method != 'get') {
		method = 'post';
		parameters += '&_method=' + options.method;
	} else {
		method = 'get'
	}

	hostnames_url = location.pathname + '/dns_hostnames/' + options.hostname_id;
	leases_url = location.pathname + '/dns_hostnames/' + options.hostname_id + '/dns_leases';

	if (timeout_delay > 0) {
		hostname_effect = new Effect.Pulsate(hostname, { duration: pulse_duration, pulses: pulses, from: 0.1 });
		if (leases.childElementCount > 0) { lease_effect = new Effect.Pulsate(leases, { duration: pulse_duration, pulses: pulses, from: 0.1 }) }
	}

	setTimeout(
		function() {
			new Ajax.Updater(hostname, hostnames_url, {
				asynchronous:true, evalScripts:true, method:method, parameters:parameters,
				onComplete: function() { hostname_effect.cancel(); Effect.Appear(hostname); } // force show of hostname once it's complete
			})

			if (leases.childElementCount > 0) {
				new Ajax.Request(leases_url, {
					asynchronous:true, evalScripts:true, method:method, parameters:parameters,
					onComplete: function() {
						$(hostname_id +'_expand_leases').hide();
						$(hostname_id+'_compress_leases').show();
						lease_effect.cancel(); Effect.Appear(leases);
					}
				})
			}

			$('loading').hide(); // make sure the loading thingie goes away
		}, (timeout_delay * 1000)
	); // 5 second delay in update to allow for dns request to process
	return false;
}

function reload_leases(options) {
	leases = $(lease_id = 'hostname_' + options.hostname_id + '_leases');

	timeout_delay = options.delay || 3;
	pulse_duration = Math.ceil(Math.sqrt(timeout_delay)) + timeout_delay;
	pulses = (Math.ceil(pulse_duration / 2) + 1)

	parameters = "authenticity_token=" + encodeURIComponent(options.auth_token);
	if (options.method && options.method != 'get') {
		method = 'post';
		parameters += '&_method=' + options.method;
	} else {
		method = 'get'
	}

	leases_url = location.pathname + '/dns_hostnames/' + options.hostname_id + '/dns_leases';

	if (leases.childElementCount > 0) {
		if (timeout_delay > 0) {
			lease_effect = new Effect.Pulsate(leases, { duration: pulse_duration, pulses: pulses, from: 0.1 })
		}

		setTimeout(
			function() {
				new Ajax.Request(leases_url, {
					asynchronous:true, evalScripts:true, method:method, parameters:parameters,
					onComplete: function() { if (timeout_delay > 0) { lease_effect.cancel(); Effect.Appear(leases); } }
				})
				$('loading').hide(); // make sure the loading thingie goes away if present
			}, (timeout_delay * 1000) + 250
		);
	}

	return false;

}

function checked_size(klass) {
    var count = 0;
    klass = klass || 'selectable_check_box';
	klass = '.'+klass;
    var myArray = $$(klass);
    for (var index = 0, len = myArray.length; index < len; ++index) {
        var item = myArray[index];
        if (item.checked) {
            count += 1;
        }
    }
    return count;
}

function confirm_selection_not_empty(empty_selection_msg, klass) {
	empty_selection_msg = empty_selection_msg || 'Your selection is empty';
    if (checked_size(klass) == 0) {
		alert(empty_selection_msg);
		return false;
    }
	return true;
}

function confirm_multiple_action(el, ctl_param_class, ctl_param_value, empty_selection_msg, confirm_msg, double_confirm_msg, double_confirm_answer, check_box_klass) {
    ctl_param_class = ctl_param_class || '.instance_command';
    ctl_param_value = ctl_param_value || 'reboot';
    empty_selection_msg = empty_selection_msg || 'Your selection is empty';
    confirm_msg = confirm_msg || '';
	double_confirm_msg = double_confirm_msg || '';
	double_confirm_answer = double_confirm_answer || 'yes';
	check_box_klass = check_box_klass || 'selectable_check_box';

    if (!confirm_selection_not_empty(empty_selection_msg, check_box_klass)) {
		return false;
    }

    if (confirm_msg == '' || confirm(confirm_msg)) {
		if (double_confirm_msg == '' || (double_confirm_answer == prompt(double_confirm_msg))) {
			$(el).next(ctl_param_class).value = ctl_param_value;
			return true;
		}
    }

    return false;
}

function switchPositionsWithMove(first, second) {
	if(typeof Effect == 'undefined')
		throw("application.js requires including script.aculo.us' effects.js library");

    var delta = Position.cumulativeOffset(first)[1] - Position.cumulativeOffset(second)[1];
    new Effect.Fade(first, {from: 1.0, to: 0.3});
    new Effect.Fade(second, {from: 1.0, to: 0.3});
    new Effect.Move(second, {x: 0, y: delta});
    new Effect.Move(first, {x: 0, y: -delta});
    new Effect.Appear(second, {from: 0.3, to: 1.0});
    new Effect.Appear(first, {from: 0.3, to: 1.0});
}

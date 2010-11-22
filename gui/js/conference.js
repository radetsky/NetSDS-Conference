var sched_strings;

function edit_cnfr(confid, confname) {
	sched_strings = new Array();
	$.getJSON('/get_json_cnfr.pl', {"id":confid}, function(data){
		$("#part_of_conf").val(data.id);
		$("#conf_oper").val(data.id);
		$("#ce_id").val('');
		$("#ce_id").val(data.id);
		$("#ce_name").val('');
		$("#ce_name").val(data.name);
		$('#schedules').empty();
		$("#next_date").val('');
		$("#next_date").val(data.next_date);
		$("#next_date").datepicker({ dateFormat: 'yy-mm-dd' });
		$("#hours_begin").val('');
		$("#hours_begin").val(data.hours_begin);
		$("#min_begin").val('');
		$("#min_begin").val(data.min_begin);
		$("#dur_hours").val('');
		$("#dur_hours").val(data.dur_hours);
		$("#dur_min").val('');
		$("#dur_min").val(data.dur_min);
		if(data.schedules.length > 0) {
			$("#next_date").attr('disabled','disabled');
			$("#hours_begin").attr('disabled','disabled');
			$("#min_begin").attr('disabled','disabled');
			$("#dur_hours").attr('disabled','disabled');
			$("#dur_min").attr('disabled','disabled');
			$("#sched").attr('checked','checked');
			$("#add_sched").button( "option", "disabled", false );
			sched_strings = data.schedules;
			for(x=0; x<data.schedules.length; x++) {
				var y = '<tr id="sched_str'+x+'"><td>'+data.schedules[x].day+'</td>';
				y += '<td>'+data.schedules[x].begin+'</td>';
				y += '<td>'+data.schedules[x].duration+'</td>';
				y += '<td onclick="remove_shedule('+x+'); return false;">';
				y += '<span class="ui-icon ui-icon-close"></span></td>';
				y += '</tr>';
				$('#schedules').append(y);
			}
		} else {
			$("#add_sched").button( "option", "disabled", true );
			$("#next_date").removeAttr("disabled");
			$("#hours_begin").removeAttr("disabled");
			$("#min_begin").removeAttr("disabled");
			$("#dur_hours").removeAttr("disabled");
			$("#dur_min").removeAttr("disabled");
			$("#next").attr('checked','checked');
		}

		if( data.pin_auth == true ) {
			$("#pin_auth").attr('checked', 'checked');
			$("#auth_string").removeAttr("disabled");
			$("#auth_string").val(data.auth_string);
		} else {
			$("#pin_auth").attr('checked', '');
			$("#auth_string").val('');
			$("#auth_string").attr('disabled','disabled');
		}
		if( data.number_auth == true ) {
			$("#number_auth").attr('checked', 'checked');
			data.auto_assemble = 0;
			$("#auto_assemble").attr('checked', '');
			$("#auto_assemble").attr('disabled','disabled');
		} else {
			$("#number_auth").attr('checked', '');
		}
		if ( data.auto_assemble == 1 ) {
			$("#auto_assemble").attr('checked', 'checked');
			$("#number_auth").attr('checked', '');
			$("#number_auth").attr('disabled','disabled');
		} else {
			$("#auto_assemble").attr('checked', '');
		}
		if ( data.lost_control == 1 ) {
			$("#lost_control").attr('checked', 'checked');
		} else {
			$("#lost_control").attr('checked', '');
		}
		if ( data.need_record == 1 ) {
			$("#need_record").attr('checked', 'checked');
		} else {
			$("#need_record").attr('checked', '');
		}
		$("#audio_lang").val(data.audio_lang);

		var rem_t_en = false;
		if(data.ph_remind == 1) {
			$("#ph_remind").attr('checked', 'checked');
			rem_t_en = true;
		} else {
			$("#ph_remind").attr('checked', '');
		}
		if(data.em_remind == 1) {
			$("#em_remind").attr('checked', 'checked');
			rem_t_en = true;
		} else {
			$("#em_remind").attr('checked', '');
		}
		if(rem_t_en) {
			$("#remind_time").val(data.remind_time);
		}

		$("#operator_list").empty();
		if(data.admin == true) {
			$("#number_b").val(data.number_b);
			for(x=0; x<data.opers.length; x++) {
				y = '<tr><td>'+data.opers[x].fname+' '+'('+data.opers[x].login+')';
				y += '</td>';
				y += '<td onclick="rem_op('+data.opers[x].oper_id+');">';
				y += '<span class="ui-icon ui-icon-close"></span></td>';
				y += '<td style="display: none;" class="hidden_op_id">';
				y += data.opers[x].oper_id+'</td></tr>';
				$("#operator_list").append(y);
			}
		} else {
			$("#operator_block").remove();
			$("#number_b_block").remove();
		}

		$("#participant_list").empty();
		for(x=0; x<data.users.length; x++) {
			y = '<tr><td>'+data.users[x].usr+'</td><td>';
			y += data.users[x].phone+'</td>';
			y += '<td onclick="rem_me('+data.users[x].phone_id;
			y += ');"><span class="ui-icon ui-icon-close"></span></td>';
			y += '<td style="display: none;" class="hidden_id">';
			y += data.users[x].phone_id+'</td></tr>';
			$("#participant_list").append(y);
		}
		$("#participant_list").sortable({ items: 'tr' });
		$("#participant_list").disableSelection();
		
		$("#edit_cnfr").dialog("open");

	});
}

function add_participant() {
	var confid = $("#part_of_conf").val();
	var added = new Array();
	$("td.hidden_id").each(function(index) {
		added[index] = $(this).text();
	});
	$.getJSON('/get_json_user_list.pl', { "cid": confid }, function(data){
		$("#participant").empty();
		$("#participant").append('<option></option>');
		user_list = data;
		for(var x=0; x<data.length; x++) {
			if(data[x].ph_list.length > 0) {
				var already = false;
				for(var y=0; y<data[x].ph_list.length; y++) {
					if(added.indexOf(data[x].ph_list[y].ph_id) > -1) {
						already = true;
					}
				}
				if(already) {
					$("#participant").append('<option value="'+data[x].uid+'" disabled="disabled">'+data[x].name+'</option>');
				} else {
					$("#participant").append('<option value="'+data[x].uid+'">'+data[x].name+'</option>');
				}
			} else {
				$("#participant").append('<option value="'+data[x].uid+'" disabled="disabled">'+data[x].name+'</option>');
			}
		}
		$("#part_phone").empty();
		$("#new_participant").dialog("open");
	});
}

function send_cnfr() {
	var lst = '';
	$("td.hidden_id").each(function(index) {
		if(index == 0) {
			lst = $(this).text();
		} else {
			lst += '+'+$(this).text();
		}
	});
	var oprs = '';
	$("td.hidden_op_id").each(function(index) {
		if(index == 0) {
			oprs = $(this).text();
		} else {
			oprs += '+'+$(this).text();
		}
	});
	var scheds = '';
	for(var x=0; x<sched_strings.length; x++) {
		if(sched_strings[x].valid) {
			scheds += sched_strings[x].day+','+sched_strings[x].begin+','+sched_strings[x].duration+'|';
		}
	}
	var qry;
	qry = 'save_cnfr.pl?'+$("#modify_cnfr").serialize();
	qry += '&phs_ids='+lst;
	qry += '&ops_ids='+oprs;
	qry += '&schedules='+scheds;
	$.getJSON(qry, function(data) {
		$("#edit_cnfr").dialog("close");
		$("#cnfrs").empty();
		$("#cnfrs").load('/cnfrs.pl');
	});
}

function start_now() {
	var lst = '';
	$("td.hidden_id").each(function(index) {
		if(index == 0) {
			lst = $(this).text();
		} else {
			lst += '+'+$(this).text();
		}
	});
	var oprs = '';
	$("td.hidden_op_id").each(function(index) {
		if(index == 0) {
			oprs = $(this).text();
		} else {
			oprs += '+'+$(this).text();
		}
	});
	var scheds = '';
	for(var x=0; x<sched_strings.length; x++) {
		if(sched_strings[x].valid) {
			scheds += sched_strings[x].day+','+sched_strings[x].begin+','+sched_strings[x].duration+'|';
		}
	}
	var qry;
	qry = 'start_cnfr.pl?'+$("#modify_cnfr").serialize();
	qry += '&phs_ids='+lst;
	qry += '&ops_ids='+oprs;
	qry += '&schedules='+scheds;
	$.getJSON(qry, function(data) {
		$("#edit_cnfr").dialog("close");
		$("#cnfrs").empty();
		$("#cnfrs").load('/cnfrs.pl');
	});

}

function auth_change() {
	if($("#number_auth").attr('checked') == true) {
		$("#auto_assemble").attr("disabled", "disabled");
	} else {
		$("#auto_assemble").attr("disabled", '');
	}
}

function assem_change() {
	if($("#auto_assemble").attr('checked') == true) {
		$("#number_auth").attr("disabled", "disabled");
	} else {
		$("#number_auth").attr("disabled", '');
	}
}

function send_part() {
	var sel_fio;
	var sel_phid;
	sel_fio = $("#participant").val();
	sel_phid = $("#part_phone").val();
	for(var x=0; x<user_list.length; x++) {
		if(user_list[x].uid == sel_fio) {
			for(var y=0; y<user_list[x].ph_list.length; y++) {
				if(user_list[x].ph_list[y].ph_id == sel_phid) {
					$("#participant_list").append('<tr><td>'+user_list[x].name+
					'</td><td>'+user_list[x].ph_list[y].phone+
					'</td><td onclick="rem_me('+user_list[x].ph_list[y].ph_id+');">'+
					'<span class="ui-icon ui-icon-close"></span></td>'+
					'<td class="hidden_id" style="display: none;">'+
					user_list[x].ph_list[y].ph_id+'</td></tr>'
					);
				}
			}
		}
	}
	$("#new_participant").dialog("close");
}

function add_operator() {
	var cnfid = $("#conf_oper").val();
	$.getJSON('/get_json_oper_list.pl', { "cid": cnfid }, function(data){
		if(data.status == 'error') {
			$("#error_text").empty();
			$("#error_text").append(data.message);
			$("#error").dialog('open');
			return;
		}
		$("#oper_item").empty();
		oper_list = data;
		var alr_oper = new Array();
		$("#operator_list tr").each(function(index) {
			alr_oper[index] = $(this).children(":last").text();
		});
		$("#oper_item").append('<option value=""></option>');
		for(var x=0; x<data.length; x++) {
			if(alr_oper.indexOf(data[x].aid) >= 0) {
				$("#oper_item").append('<option value="'+data[x].aid+'" disabled="disabled">'+data[x].name+' ('+data[x].login+') '+'</option>');
			} else {
				$("#oper_item").append('<option value="'+data[x].aid+'">'+data[x].name+' ('+data[x].login+') '+'</option>');
			}
		}
		$("#new_oper").dialog("open");
	});
}

function send_oper() {
	var sel_oper;
	sel_oper = $("#oper_item").val();
	for(var x=0; x<oper_list.length; x++) {
		if(sel_oper == oper_list[x].aid) {
			a = '<tr><td>'+oper_list[x].name+' '+'('+oper_list[x].login+')';
			a += '</td>';
			a += '<td onclick="rem_op('+oper_list[x].aid+');">';
			a += '<span class="ui-icon ui-icon-close"></span></td>';
			a += '<td style="display: none;" class="hidden_op_id">';
			a += oper_list[x].aid+'</td></tr>';
			$("#operator_list").append(a);
		}
	}
	$("#new_oper").dialog("close");
}

function rem_me(ph_id) {
	$("#participant_list tr").each(function() {
		if($(this).children(":last").text() == ph_id) {
			$(this).remove();
		}
	});
}

function rem_op(op_id) {
	$("#operator_list tr").each(function() {
		if($(this).children(":last").text() == op_id) {
			$(this).remove();
		}
	});
}

function select_phones() {
	var sel_fio;
	$("#part_phone").empty();
	sel_fio = $("#participant").val();
	for(var x=0; x<user_list.length; x++) {
		if(user_list[x].uid == sel_fio) {
			for(var y=0; y<user_list[x].ph_list.length; y++) {
				$("#part_phone").append('<option value="'+user_list[x].ph_list[y].ph_id+'">'+user_list[x].ph_list[y].phone+'</option>');
			}
		}
	}
}

function add_schedule() {
	$("#date-selectable .ui-selected").each(function(){
		$(this).toggleClass("ui-selected", false);
	});
	$("#day-selectable .ui-selected").each(function(){
		$(this).toggleClass("ui-selected", false);
	});
	$("#sched-day").attr('checked', true);
	$("#day-selectable").selectable("enable");
	$("#date-selectable").selectable("disable");
	$('#schedule_hours_begin').val('');
	$('#schedule_min_begin').val('');
	$('#sched_dur_hours').val('');
	$('#sched_dur_min').val('');
	$("#schedule_select").dialog('open');
}

function fill_sched() {
	var ddd = '';
	if($("#sched-day").attr("checked") == true) {
		$("#day-selectable .ui-selected").each(function(){
			ddd += $(this).text()+' ';
		});
	} else {
		$("#date-selectable .ui-selected").each(function(){
			ddd += $(this).text()+' ';
		});
	}
	if(ddd == '') {
  	$("#error_text").empty();
		$("#error_text").append('Не задан день планируемой конференции');
		$("#error").dialog('open');
		return false;
	}
	if($('#schedule_hours_begin').val() == '' || $('#schedule_min_begin').val() == '') {
  	$("#error_text").empty();
		$("#error_text").append('Не задано время начала планируемой конференции');
		$("#error").dialog('open');
		return false;
	}
	if($('#sched_dur_hours').val() == '' || $('#sched_dur_min').val() == '') {
  	$("#error_text").empty();
		$("#error_text").append('Не задана продолжительность планируемой конференции');
		$("#error").dialog('open');
		return false;
	}
	var i = sched_strings.length;
	sched_strings[i] = new Object();
	var y = '<tr id="sched_str'+i+'"><td>'+ddd+'</td>';
	sched_strings[i].day = ddd;
	sched_strings[i].begin = $('#schedule_hours_begin').val()+':'+$('#schedule_min_begin').val();
	sched_strings[i].duration = $('#sched_dur_hours').val()+':'+$('#sched_dur_min').val();
	sched_strings[i].valid = true;
	y += '<td>'+$('#schedule_hours_begin').val()+':'+$('#schedule_min_begin').val()+'</td>';
	y += '<td>'+$('#sched_dur_hours').val()+':'+$('#sched_dur_min').val()+'</td>';
	y += '<td onclick="remove_shedule('+i+'); return false;">';
	y += '<span class="ui-icon ui-icon-close"></span></td>';
	y += '</tr>';
	$('#schedules').append(y);
//	$("#schedule_day").val(ddd);
	$('#schedule_select').dialog("close");
}

function remove_shedule(ind) {
	sched_strings[ind].valid = false;
	$('#sched_str'+ind).remove();
}

function close_cnfr_dialog() {
	$("#edit_cnfr").dialog("close");
}

function close_part_dialog() {
	$('#new_participant').dialog("close");
}

function close_oper_dialog() {
	$('#new_oper').dialog("close");
}

function close_sched_dialog() {
	$('#schedule_select').dialog("close");
}

function remind_change() {
	if($('#ph_remind').attr('checked') == true || $('#em_remind').attr('checked') == true) {
		$('#remind_time').removeAttr("disabled");
	} else {
		$('#remind_time').attr('disabled', 'disabled');
		$('#remind_time').val('00:15:00');
	}
}

var logins = new Object;
var logoffs = new Object;
var channels = new Object;
var pongs = new Object;
var loggedon = -1;

var watcher = new Object;

var conference_id = -1;
var online_conf = new Array();
var msgs_cont = new Object;

watcher.logins = function(msgs) {
	response = msgs[0].headers['response'];
	if (response == 'Error') { 
		alert('Ошибка подключения к rawman: ' +  msgs[0].headers['message'] );
		return false; 
	}
        astmanEngine.pollEvents();
}

function doLogin(username,secret) {
	astmanEngine.sendRequest('action=login&username=' + username + "&secret=" + secret, watcher.logins);
}

watcher.eventCB = function(msgs) {
	var eventname; 
  var found = false; 
	var next_ids = 0; 

	for (x=0;x<msgs.length;x++) {
		eventname = msgs[x].headers['event'];
//
// Someone speaking or not.
// 
		if(eventname == 'ConferenceState') {
				for(y=0; y<online_conf.length; y++) {
					if(online_conf[y].channel == msgs[x].headers['channel']) {
						$('#st'+y).empty();
						if( msgs[x].headers['state'] == 'speaking') {
							$('#st'+y).append('<img src="/css/images/thumbs_063449-green-grunge-clipart-icon-people-things-speech.png" alt="Говорит"/>');
						} else {
							$('#st'+y).append('<img src="/css/images/thumbs_063565-green-jelly-icon-people-things-people-head.png" alt="Молчит"/>');
						}
					}
				}
		}
		
		if(msgs[x].headers['conferencename'] == conference_id) {
			//alert (eventname + ' ' + conference_id + ' ' + msgs[x].headers['callerid']); 
		  found = false;
			for(y=0; y<online_conf.length; y++) {
				if(online_conf[y].phone == msgs[x].headers['callerid']) {
					found = true;
					$('#st'+y).empty();
					if (eventname == 'ConferenceJoin') {
						$('#st'+y).append('<img src="/css/images/thumbs_063565-green-jelly-icon-people-things-people-head.png" alt="Молчит"/>');
						online_conf[y].channel = msgs[x].headers['channel'];
						online_conf[y].member_id = msgs[x].headers['member'];
						$('#td_mute'+y).empty();
						$('#td_mute'+y).append('<input id="mute'+y+'" type="image" src="css/images/green_mphone.png" value="green" onclick="change_mute('+y+',\''+online_conf[y].channel+'\'); return false;"/>');
						$('#td_drop'+y).empty();
						$('#td_drop'+y).append('<input type="image" src="css/images/drop.png" onclick="drop_line('+y+'); return false;" />');
						$('#hidin'+y).append('<input type="hidden" id="chan'+y+'" value="'+online_conf[y].channel+'" />');
						$('#dn'+y).slider("option", "disabled", false);
						$('#ph'+y).slider("option", "disabled", false);
						$("#sel"+y).removeAttr("disabled");
					}
					if (eventname == 'ConferenceLeave') {
						$('#st'+y).append('<img src="/css/images/thumbs_003207-green-jelly-icon-media-a-media292-minus3.png" alt="Отключен"/>');
						$('#td_mute'+y).empty();
						$('#td_mute'+y).append('<img src="css/images/grey_mphone.png" alt="Offline" />');
						$('#td_drop'+y).empty();
						$('#td_drop'+y).append('<img src="css/images/drop_grey.png" alt="drop" />');
						$('#chan'+y).remove();
						$('#dn'+y).slider("option", "disabled", true);
						$('#ph'+y).slider("option", "disabled", true);
						if($("#sel"+y).attr("checked") == true) {
							$.getJSON('set_priority.pl', {"cid": conference_id, "phid": "empty"});
						}
						$("#sel"+y).removeAttr("checked");
						$("#sel"+y).attr("disabled", "disabled");
					}
				}
			}

			if(!found) {
				msgs_cont = msgs[x];
				next_idx = online_conf.length;
				online_conf.length = next_idx+1;
				online_conf[next_idx] = new Object;
				$.getJSON('/guest_suggest.pl', { "phone": msgs[x].headers['callerid'] }, function(data){
					if(data.known) {
						online_conf[next_idx].phone_id = data.phone_id;
						online_conf[next_idx].user_id = data.user_id;
					}
					online_conf[next_idx].channel = msgs_cont.headers['channel'];
					online_conf[next_idx].member_id = msgs_cont.headers['member'];
					online_conf[next_idx].user_name = data.user_name;
					online_conf[next_idx].phone = msgs_cont.headers['callerid'];
					y = '<tr><td rowspan="2">'+data.user_name+'</td>';
					y += '<td rowspan="2">&nbsp;</td>';
					st = 'st'+next_idx;
					y += '<td rowspan="2" id="st'+next_idx+'"><img src="/css/images/thumbs_063565-green-jelly-icon-people-things-people-head.png" alt="Молчит"/></td>';
					y += '<td><img src="/css/images/mphone_icon.png" alt="Microph" /></td>';
					y += '<td class="vol-slider" id="hidin'+x+'"><div id="ph'+next_idx+'"></div>';
					y += '<input type="hidden" id="chan'+next_idx+'" value="'+online_conf[next_idx].channel+'" />';
					y += '</td>';
					y += '<td rowspan="2" id="td_mute'+next_idx+'"><input id="mute'+next_idx+'" type="image" src="css/images/green_mphone.png" value="green" onclick="change_mute('+next_idx+',\''+online_conf[next_idx].channel+'\'); return false;"/></td>';
					y += '<td rowspan="2" id="td_drop'+next_idx+'"><input type="image" src="css/images/drop.png" onclick="drop_line('+next_idx+'); return false;" /></td>';
					y += '<td rowspan="2">'+online_conf[next_idx].phone+'</td></tr>';
					y += '<tr><td><img src="/css/images/dyn_icon.png" alt="Dyn" /></td>';
					y += '<td class="vol-slider"><div id="dn'+next_idx+'"></div></td></tr>';
					$("#show_active table").append(y);
					$("#ph"+next_idx).slider({
						value: 10, min: 0, max: 20, step: 10,
						change: function (event, ui) {
							if(ui.value != 10) {
								$(this).slider("option", "value", 10);
								var nmb = $(this).attr('id').substr(2);
								var act = 'action=command&command=konference%20talkvolume%20'+$('#chan'+nmb).val()+'%20';
								if(ui.value == 0) {
									act += 'down';
								} else {
									act += 'up';
								}
								astmanEngine.sendRequest(act);
								astmanEngine.sendRequest(act);
								astmanEngine.sendRequest(act);
							}
						}
					});
					$("#dn"+next_idx).slider({
						value: 10, min: 0, max: 20, step: 10,
						change: function (event, ui) {
							if(ui.value != 10) {
								$(this).slider("option", "value", 10);
								var nmb = $(this).attr('id').substr(2);
								var act = 'action=command&command=konference%20listenvolume%20'+$('#chan'+nmb).val()+'%20';
								if(ui.value == 0) {
									act += 'down';
								} else {
									act += 'up';
								}
								astmanEngine.sendRequest(act);
								astmanEngine.sendRequest(act);
								astmanEngine.sendRequest(act);
							}
						}
					});
				});
			}
		}
	}

	astmanEngine.pollEvents();
}

function set_pr(phid) {
	$.getJSON('set_priority.pl', {"cid": conference_id, "phid": phid});
}

function show_active(confid, confname) {

	conference_id = confid;
	$("#show_active table").empty();
// Create a dialog 	
	$("#show_active").dialog("option", "title", confname);
// Create 'remove prio' button 
	$("#rem_prior").button();
	$("#rem_prior").click( function() {
		$(".prior").removeAttr("checked");
		$.getJSON('set_priority.pl', {"cid": conference_id, "phid": "empty"});
		return false;
	});

// Create 'stop conference' button 
	$("#stop_cnfr").button();
	$("#stop_cnfr").click( function() {
		var request = $.ajax ('stop_cnfr.pl' , {
			type: "GET",
			data: {"cid": conference_id}, 
 			dataType: "json",
		});
		request.done (function (msg) { 
			alert ("Конференция остановлена!");
			$("#stop_cnfr").off(); // Remove handler from button 'stop' 
	                $("#show_active").dialog("close");
			return false;
		});
		request.fail(function(jqXHR, textStatus, errorThrown) {
                        alert( "stop_cnfr request failed: " + textStatus + errorThrown);
			return false; 
                });
		return false;
	});

// Создаем запрос на сервер для инциализации окна активной конференции 
 
	$.getJSON('get_json_active.pl', {"cid": confid}, function(data) {
		if(data.status == 'error') {
			$("#error_text").empty();
			$("#error_text").append(data.message);
			$("#error").dialog('open');
			return;
		}
// Обрабатываем полученные данные 
		online_conf = data;
		for(x=0; x<data.length; x++) {
			y = '<tr><td rowspan="2">'+data[x].user_name+'</td>'; // Имя абонента 
			y += '<td rowspan="2">';
			if(data[x].known) {  // Если пользователь "знакомый" 
				if(data[x].state == 'offline') { 
					y += '<input type="radio" id="sel'+x+'" class="prior" name="pr_user" onchange="set_pr('+data[x].phone_id+');" disabled="disabled" /></td>';
				} else {
					y += '<input type="radio" id="sel'+x+'" class="prior" name="pr_user" onchange="set_pr('+data[x].phone_id+');"/></td>';
				}    // Выставили кнопки приоритета. 
			} else {
				y += '&nbsp;</td>'; //  Если пользователь не знакомый, то кнопки приоритета ему не положено. 
			}

			if(data[x].state == 'offline') {
				y += '<td rowspan="2" id="st'+x+'"><img src="/css/images/thumbs_003207-green-jelly-icon-media-a-media292-minus3.png" alt="Отключен"/></td>';
			} else {
				y += '<td rowspan="2" id="st'+x+'"><img src="/css/images/thumbs_063565-green-jelly-icon-people-things-people-head.png" alt="Молчит"/></td>';
			}
			y += '<td><img src="/css/images/mphone_icon.png" alt="Microph" /></td>';
			y += '<td class="vol-slider" id="hidin'+x+'"><div id="ph'+x+'"></div>';
			if(data[x].state == 'online') {
				y += '<input type="hidden" id="chan'+x+'" value="'+data[x].channel+'" />';
			}
			y += '</td>';
			y += '<td rowspan="2" id="td_mute'+x+'">';
			if(data[x].state == 'offline') {
				y += '<img src="css/images/grey_mphone.png" alt="Offline" />';
			} else {
				y += '<input id="mute'+x+'" type="image" src="css/images/green_mphone.png" value="green" onclick="change_mute('+x+',\''+data[x].channel+'\'); return false;"/>';
			}
			y += '</td>';
			y += '<td rowspan="2" id="td_drop'+x+'">';
			if(data[x].state == 'offline') {
				y += '<img src="css/images/drop_grey.png" alt="drop" />';
			} else {
				y += '<input type="image" src="css/images/drop.png" onclick="drop_line('+x+'); return false;" />';
			}
			y += '</td>';
			y += '<td rowspan="2">'+data[x].phone+'</td></tr>';
			y += '<tr><td><img src="/css/images/dyn_icon.png" alt="Dyn" /></td>';
			y += '<td class="vol-slider"><div id="dn'+x+'"></div>';
			y += '</td></tr>';

// Добавили новую строку в таблицу 

			$("#show_active table").append(y);
// Назначаем слайдерам свойства 
			$('#ph'+x).slider({
				value: 10, min: 0, max: 20, step: 10,
				change: function (event, ui) {
					if(ui.value != 10) {
						$(this).slider("option", "value", 10);
						var nmb = $(this).attr('id').substr(2);
						var act = 'action=command&command=konference%20talkvolume%20'+$('#chan'+nmb).val()+'%20';
						if(ui.value == 0) {
							act += 'down';
						} else {
							act += 'up';
						}
						astmanEngine.sendRequest(act);
						astmanEngine.sendRequest(act);
						astmanEngine.sendRequest(act);
					}
				}
			});
			$('#dn'+x).slider({
				value: 10, min: 0, max: 20, step: 10,
				change: function (event, ui) {
					if(ui.value != 10) {
						$(this).slider("option", "value", 10);
						var nmb = $(this).attr('id').substr(2);
						var act = 'action=command&command=konference%20listenvolume%20'+$('#chan'+nmb).val()+'%20';
						if(ui.value == 0) {
							act += 'down';
						} else {
							act += 'up';
						}
						astmanEngine.sendRequest(act);
						astmanEngine.sendRequest(act);
						astmanEngine.sendRequest(act);
					}
				}
			});
			if(data[x].state == 'offline') {
				$('#ph'+x).slider("option", "disabled", true);
				$('#dn'+x).slider("option", "disabled", true);
			}
		}
	});
	$("#show_active").dialog('open');
	var myurl = "/konference/rawman";
	astmanEngine.setURL(myurl);
	astmanEngine.setEventCallback(watcher.eventCB);
	doLogin('konference','MoNit040fConf');
}

function change_mute(mid,channel) {
	but = $('#mute'+mid).val();
	if(but == 'green') {
		astmanEngine.sendRequest('action=command&command=konference%20mutechannel%20'+channel,watcher.eventCB);
		$('#mute'+mid).val('red');
		$('#mute'+mid).attr('src', 'css/images/red_mphone.png');
		$('#st'+mid).empty();
		$('#st'+mid).append('<img src="/css/images/thumbs_063565-green-jelly-icon-people-things-people-head.png" alt="Молчит"/>');
	} else {
		astmanEngine.sendRequest('action=command&command=konference%20unmutechannel%20'+channel,watcher.eventCB);

		$('#mute'+mid).val('green');
		$('#mute'+mid).attr('src', 'css/images/green_mphone.png');
	}
}

function drop_line(mid) {
	astmanEngine.sendRequest('action=command&command=konference%20kickchannel%20'+online_conf[mid].channel);
}

function current_time() { 
	var now = new Date(); 
	var t = now.getHours()+":"+now.getMinutes()+":"+now.getSeconds();
	return t; 
} 


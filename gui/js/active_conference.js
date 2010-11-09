var logins = new Object;
var logoffs = new Object;
var channels = new Object;
var pongs = new Object;
var loggedon = -1;

var watcher = new Object;

var conference_id = -1;
var online_conf = new Object;

watcher.logins = function(msgs) {
	eventname = msgs[0].headers['response'];
//	alert(eventname); 
	astmanEngine.pollEvents(); 
}

function doLogin(username,secret) {
	astmanEngine.sendRequest('action=login&username=' + username + "&secret=" + secret, watcher.logins);
}

watcher.eventCB = function(msgs) {
	
	for (x=0;x<msgs.length;x++) {
		eventname = msgs[x].headers['event'];
		if(eventname == 'ConferenceState') {
//			alert(msgs[x].headers['state']);
//			alert('online_conf.length='+online_conf.length);
//			alert('caller_id='+msgs[x].headers['channel']);
			for(y=0; y<online_conf.length; y++) {
				if(online_conf[y].channel == msgs[x].headers['channel']) {
//				alert(msgs[x].headers['state']);
					$('#st'+y).empty();
					if( msgs[x].headers['state'] == 'speaking') {
						$('#st'+y).append('Говорит');
					} else {
						$('#st'+y).append('Молчит');
					}
				}
			}
		}
//	    for(y=0;y<msgs[x].names.length;y++) {
//		alert('names='+msgs[x].names[y]);
//	    }
		if(msgs[x].headers['conferencename'] == conference_id) {
			for(y=0; y<online_conf.length; y++) {
				if(online_conf[y].phone == msgs[x].headers['callerid']) {
					$('#st'+y).empty();
					if (eventname == 'ConferenceJoin') {
						$('#st'+y).append('Молчит');
						online_conf[y].channel = msgs[x].headers['channel'];
					}
					if (eventname == 'ConferenceLeave') {
						$('#st'+y).append('Отключен');
					}
				}
			}
		}
//		if(conference_id == msgs[x].headers['conferencename']) {
//			eventname = msgs[x].headers['event'];
//			alert(eventname);
//		}
	}

	astmanEngine.pollEvents();
}

function show_active(confid) {
	conference_id = confid;
	$.getJSON('get_json_active.pl', {"cid": confid}, function(data) {
		if(data.status == 'error') {
			$("#error_text").empty();
			$("#error_text").append(data.message);
			$("#error").dialog('open');
			return;
		}
		$("#show_active table").empty();
		online_conf = data;
		for(x=0; x<data.length; x++) {
			y = '<tr><td rowspan="2">'+data[x].user_name+'</td>';
			y += '<td rowspan="2"><input type="radio" name="pr_user" value="'+data[x].user_id+'"/></td>';
			st = 'st'+x;
			if(data[x].state == 'offline') {
				y += '<td rowspan="2" id="'+st+'">Отключен</td>';
			} else {
				y += '<td rowspan="2" id="'+st+'">Молчит</td>';
			}
			ph = 'ph'+x;
			dn = 'dn'+x;
			y += '<td class="vol-slider"><div id="'+ph+'"></div></td>';
			y += '<td rowspan="2"><input id="mute'+x+'" type="image" src="css/images/green_mphone.png" value="green" onclick="change_mute('+x+'); return false;"/></td>';
			y += '<td rowspan="2"><img src="css/images/drop.png" alt="drop"/></td>';
			y += '<td rowspan="2">'+data[x].phone+'</td></tr>';
			y += '<tr><td class="vol-slider"><div id="'+dn+'"></div></td></tr>';
			$("#show_active table").append(y);
			$("#"+ph).slider({value: 20, min: 0, max: 40, step: 10});
			$("#"+dn).slider({value: 20, min: 0, max: 40, step: 10});
		}
		$("#show_active").dialog('open');
		var myurl = "/konference/rawman";
		astmanEngine.setURL(myurl);
		astmanEngine.setEventCallback(watcher.eventCB);
		doLogin('konference','MoNit040fConf');
	});
}

function change_mute(mid) {
	but = $('#mute'+mid).val();
	if(but == 'green') {
		$('#mute'+mid).val('red');
		$('#mute'+mid).attr('src', 'css/images/red_mphone.png');
	} else {
		$('#mute'+mid).val('green');
		$('#mute'+mid).attr('src', 'css/images/green_mphone.png');
	}
}

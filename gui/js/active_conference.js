var logins = new Object;
var logoffs = new Object;
var channels = new Object;
var pongs = new Object;
var loggedon = -1;

var watcher = new Object;

watcher.logins = function(msgs) {
	$('statusbar').innerHTML = msgs[0].headers['message'];
	astmanEngine.pollEvents(); 
}

function doLogin(username,secret) {
	$('statusbar').innerHTML = "<i>Logging in...</i>";
	astmanEngine.sendRequest('action=login&username=' + username + "&secret=" + secret, watcher.logins);
}

watcher.eventCB  = function(msgs) {
	alert('watcher work');
}

function show_active(confid) {
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
			y += '<td rowspan="2">'+data[x].state+'</td>';
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

		astmanEngine.setURL('http://conference.netstyle.com.ua:8081/konference/rawman');
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

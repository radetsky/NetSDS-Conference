/**
*
*  AJAX IFRAME METHOD (AIM)
*  http://www.webtoolkit.info/
*
**/
 
AIM = {
 
	frame : function(c) {
 
		var n = 'f' + Math.floor(Math.random() * 99999);
		var d = document.createElement('DIV');
		d.innerHTML = '<iframe style="display:none" src="about:blank" id="'+n+'" name="'+n+'" onload="AIM.loaded(\''+n+'\')"></iframe>';
		document.body.appendChild(d);
 
		var i = document.getElementById(n);
		if (c && typeof(c.onComplete) == 'function') {
			i.onComplete = c.onComplete;
		}
 
		return n;
	},
 
	form : function(f, name) {
		f.setAttribute('target', name);
	},
 
	submit : function(f, c) {
		AIM.form(f, AIM.frame(c));
		if (c && typeof(c.onStart) == 'function') {
			return c.onStart();
		} else {
			return true;
		}
	},
 
	loaded : function(id) {
		var i = document.getElementById(id);
		if (i.contentDocument) {
			var d = i.contentDocument;
		} else if (i.contentWindow) {
			var d = i.contentWindow.document;
		} else {
			var d = window.frames[id].document;
		}
		if (d.location.href == "about:blank") {
			return;
		}
 
		if (typeof(i.onComplete) == 'function') {
			i.onComplete(d.body.innerHTML);
		}
	}
 
}

function startCallback() {
	// make something useful before submit (onStart)
	var name = $('#fname').val();
	if(name.length == 0) {
		$("#error_text").empty();
		$("#error_text").append('Файл нужно как-нибудь назвать, чтобы было понятно, что в нем содержится');
		$("#error").dialog('open');
		return false;
	}
	var fname = $('#fbody').val();
	if(fname.length == 0) {
		$("#error_text").empty();
		$("#error_text").append('Не выбран файл для загрузки');
		$("#error").dialog('open');
		return false;
	}
	var nparts = fname.split('.');
	var i = nparts.length - 1;
	if(nparts[i] != 'wav') {
		$("#error_text").empty();
		$("#error_text").append('Загружать можно только wav файлы!');
		$("#error").dialog('open');
		$('#fbody').val('');
		return false;
	}

	return true;
}
 
function completeCallback(response) {
	// make something useful after (onComplete)
//	document.getElementById('nr').innerHTML = parseInt(document.getElementById('nr').innerHTML) + 1;
//	document.getElementById('r').innerHTML = response;
	var stl = response.length - 11;
	var msg = response.substr(5, stl);
	if(msg == 'ok') {
		$('#audio').empty();
		$('#audio').load('/audio.pl');
		return true;
	} else {
		$("#error_text").empty();
		$("#error_text").append(msg);
		$("#error").dialog('open');
		$('#fname').val('');
		$('#fbody').val('');
		return false;
	}
}

function remove_audio(auid) {
	$.getJSON('/remove_audio.pl', {"auid":auid}, function(data){
		if(data.status == 'error') {
			$("#error_text").empty();
			$("#error_text").append(data.message);
			$("#error").dialog('open');
			return false;
		}
		$('#audio'+auid).remove();
		return true;
	});
}

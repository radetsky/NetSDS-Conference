			/* 
			 * -- Simple Views (tabs with external handles)
			 * -- bugs by protopartorg@gmail.com
			 */
		
			var activeView = false;
			var loading = 0;
			var loops = 120;
			
			function registerView ( viewId, loadUrl ) {
				var view = $('#'+viewId);
				if (!view.length) return;
				var handle = $('#handle-'+viewId);
				if (!handle.length) return;
				
				view.hide(0);
				if (loadUrl != '') { 
					loading++;
					view.load(loadUrl, function () {
						loading--;
					});
				}
				
				handle.click(function () {
					$('#handle-'+activeView).removeClass('activeHandle');
					$('#handle-'+activeView).addClass('inactiveHandle');
					$(this).addClass('activeHandle');
					$(this).removeClass('inactiveHandle');
					$('#'+activeView).hide(0);
					var arr = this.id.split('-');
					var newViewId = arr[1];
					$('#'+newViewId).show(0);
					activeView = newViewId;
					return false;
				});
				
				if (!activeView) {
					activeView = viewId;
					handle.addClass('activeHandle');
					view.show(0);
				} else {
					handle.addClass('inactiveHandle');
				}
			}
			
			function whenViewsDone (fire) {
				if ((loading <= 0) || (loops <=0)) {
					fire();
				} else {
					loops--;
					setTimeout(function(){whenViewsDone(fire);},500);
				}
			}
		

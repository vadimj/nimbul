function tabselect(tab, tabcontrol) {
  var control = tabcontrol || 'tabcontrol1';
  var tablist = $(control).getElementsByTagName('li');
  var nodes = $A(tablist);
  var lClassType = tab.className.substring(0, tab.className.indexOf('-') );

  nodes.each(function(node){
    if (node.id == tab.id) {
      tab.className=lClassType+'-selected';
    } else {
      node.className=lClassType+'-unselected';
    };
  });
}

function paneselect(pane, panecontrol) {
  var control = panecontrol || 'panecontrol1';
  var panelist = $(control).getElementsByTagName('li');
  var nodes = $A(panelist);

  nodes.each(function(node){
    if (node.id == pane.id) {
      pane.className='pane-selected';
    } else {
      node.className='pane-unselected';
    };
  });
}

function loadPane(pane, src) {
  if (pane.innerHTML=='') {
    reloadPane(pane, src);
  }
}

function reloadPane(pane, src) {
  new Ajax.Updater(pane, src, {method:'get', asynchronous:1, evalScripts:true})
}

function loadDiv(div, src) {
  if (div.innerHTML=='') {
    new Ajax.Request(src, {method:'get', asynchronous:1, evalScripts:true})
  }
}

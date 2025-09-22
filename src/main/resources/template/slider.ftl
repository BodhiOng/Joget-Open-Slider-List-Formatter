<!-- Advanced Slider with Tabs -->
<div id="sideSlider" aria-hidden="true">
  <div id="sliderHeader">
    <span id="sliderTitle">Viewer</span>
    <div>
      <button id="minimizeSlider" title="Minimize">_</button>
      <button id="closeSlider" title="Close">×</button>
    </div>
  </div>
  <div id="sliderBody">
    <iframe id="sliderFrame" src="about:blank" frameborder="0"
      sandbox="allow-same-origin allow-scripts allow-forms allow-popups"></iframe>
    <div id="blockedNotice" style="display:none;padding:18px;text-align:center;">
      <div style="font-weight:600;margin-bottom:8px;">Cannot display this site inside the slider</div>
      <div style="margin-bottom:12px;color:#444">Many sites block embedding (X-Frame-Options / CSP).</div>
      <div>
        <button id="openNewTabBtn">Open in new tab</button>
        <button id="openPopupBtn">Open in popup</button>
      </div>
    </div>
  </div>
</div>
<div id="tabBar" aria-label="Tab bar"></div>

<style>
  #sideSlider { 
    position: fixed; 
    top: 0; 
    right: -70%;
    width: ${width!}; 
    max-width: 980px; 
    min-width: 360px; 
    height: 100%;
    background: #fff; 
    box-shadow: -2px 0 8px rgba(0,0,0,0.2);
    transition: right .32s ease; 
    z-index: 99999; 
    display: flex; 
    flex-direction: column; 
  }
  #sideSlider.open { right: 0; }
  #sideSlider.minimized { right: -70%; height: 0; overflow: hidden; }
  #sliderHeader { 
    display: flex; 
    justify-content: space-between; 
    align-items: center;
    padding: 8px 12px; 
    background: #f7f7f7; 
    border-bottom: 1px solid #ddd; 
    height: 44px; 
    box-sizing: border-box; 
  }
  #sliderHeader #sliderTitle { 
    font-weight: 600; 
    overflow: hidden; 
    text-overflow: ellipsis;
    white-space: nowrap; 
    max-width: 70%; 
  }
  #sliderHeader button { 
    margin-left: 6px; 
    border: 0; 
    background: #eee; 
    cursor: pointer;
    font-size: 16px; 
    padding: 6px 8px; 
    border-radius: 4px; 
  }
  #sliderBody { position: relative; flex: 1; min-height: 0; }
  #sliderFrame { width: 100%; height: 100%; border: 0; display: block; }
  #blockedNotice { 
    position: absolute; 
    inset: 0; 
    display: flex; 
    align-items: center;
    justify-content: center; 
    background: rgba(255,255,255,0.98); 
  }
  #tabBar { 
    position: fixed; 
    bottom: 0; 
    left: 0; 
    right: 0; 
    background: #222; 
    padding: 6px;
    display: none; /* Hide by default, will be shown when tabs are present */
    gap: 6px; 
    overflow-x: auto; 
    z-index: 100000; 
    min-height: 36px; /* Ensure minimum height for visibility */
  }
  #tabBar .tab { 
    display: flex; 
    align-items: center; 
    gap: 8px; 
    padding: 6px 10px;
    background: #444; 
    color: #fff; 
    border-radius: 6px; 
    cursor: pointer; 
    white-space: nowrap; 
  }
  #tabBar .tab.active { background: #1976d2; }
  #tabBar .tab button.closeTab { 
    border: 0; 
    background: transparent; 
    color: #fff; 
    cursor: pointer;
    font-size: 14px; 
    padding: 0 4px; 
  }
  #tabBar .tab .label { 
    max-width: 200px; 
    overflow: hidden; 
    text-overflow: ellipsis; 
  }
</style>

<script>
(function () {
    // Reset the injection flag on each page load/refresh
    window.__jw_slider_injected = true;
    
    // --- Elements & state ---
    const slider = document.getElementById('sideSlider');
    const sliderFrame = document.getElementById('sliderFrame');
    const sliderTitle = document.getElementById('sliderTitle');
    const blockedNotice = document.getElementById('blockedNotice');
    const openNewTabBtn = document.getElementById('openNewTabBtn');
    const openPopupBtn = document.getElementById('openPopupBtn');
    const tabBar = document.getElementById('tabBar');

    let tabs = {};
    let activeUrl = null;
    let iframePollId = null;

    // --- helpers ---
    function normalizeUrl(raw) {
        if (!raw) return null;
        try { return new URL(raw, window.location.origin).href; }
        catch { return null; }
    }
    // HTML escaping is now done inline where needed

    // Refresh the datalist only
    function refreshList() {
        try {
            const list = document.getElementById("list_website_form");
            if (list && typeof list.refresh === "function") {
                list.refresh(); // Joget native refresh
            } else {
                // fallback: click first pagination link to force reload
                const firstPager = document.querySelector("#list_website_form .pagelinks a");
                if (firstPager) firstPager.click();
                else window.location.reload();
            }
        } catch (e) {
            window.location.reload();
        }
    }

    function showBlocked(url) {
        sliderFrame.style.display = 'none';
        blockedNotice.style.display = 'flex';
        openNewTabBtn.onclick = () => window.open(url, '_blank', 'noopener');
        openPopupBtn.onclick = () => {
            const windowWidth = Math.min(window.innerWidth - 120, 1100);
            const windowHeight = Math.min(window.innerHeight - 120, 800);
            window.open(url, '_blank', 'width=' + windowWidth + ',height=' + windowHeight + ',left=50,top=50');
        };
    }
    function hideBlocked() {
        blockedNotice.style.display = 'none';
        sliderFrame.style.display = 'block';
        openNewTabBtn.onclick = null;
        openPopupBtn.onclick = null;
    }

    function createTab(url, title) {
        if (tabs[url]) return;
        
        // Generate tab name based on index
        const tabName = getTabName();
        
        const tab = document.createElement('div');
        tab.className = 'tab';
        tab.dataset.url = url;
        tab.dataset.number = tabCounter; // Store the tab number for reference
        
        tab.innerHTML = '<span class="label">' + tabName + '</span><button class="closeTab">×</button>';
        tab.querySelector('.label').addEventListener('click', () => setActiveTab(url));
        tab.querySelector('.closeTab').addEventListener('click', (e) => { e.stopPropagation(); removeTab(url); });
        tabBar.appendChild(tab);
        tabs[url] = { el: tab, title: tabName, number: tabCounter };
        
        // Show the tab bar when a tab is created
        tabBar.style.display = 'flex';
    }

    function setActiveTab(url) {
        console.log('setActiveTab called with:', url);
        if (!tabs[url]) {
            console.error('Tab not found for URL:', url);
            return;
        }
        
        try {
            // Reset all tabs to inactive state
            Object.values(tabs).forEach(t => {
                if (t && t.el) t.el.classList.remove('active');
            });
            
            // Set this tab as active
            if (tabs[url] && tabs[url].el) {
                tabs[url].el.classList.add('active');
            }
            
            // Ensure slider is in the correct state - force it
            slider.style.display = 'flex';
            slider.classList.add('open');
            slider.classList.remove('minimized');
            
            // Update active URL and title
            activeUrl = url;
            
            // Set the slider title to the tab name
            sliderTitle.textContent = tabs[url].title || 'View';
            
            // Reset content and start monitoring
            hideBlocked();
            
            // Force a longer delay before setting the iframe src to ensure DOM is ready
            setTimeout(() => {
                // Double check the slider is still visible
                slider.classList.add('open');
                slider.classList.remove('minimized');
                
                // Set the iframe source
                sliderFrame.src = url;
                startIframeWatch();
                
                // Make sure tab bar is visible
                tabBar.style.display = 'flex';
            }, 100);
        } catch (err) {
            console.error('Error in setActiveTab:', err);
        }
    }

    function removeTab(url) {
        if (!tabs[url]) return;
        const wasActive = (activeUrl === url);
        tabs[url].el.remove();
        delete tabs[url];
        
        // Check if there are any remaining tabs
        const keys = Object.keys(tabs);
        
        if (keys.length === 0) {
            // Hide the tab bar when no tabs are present
            tabBar.style.display = 'none';
            
            // Reset tab counter when all tabs are closed
            resetTabCounter();
        }
        
        if (wasActive) {
            if (keys.length) {
                setActiveTab(keys[0]);
            } else {
                // Just minimize the slider
                slider.classList.remove('open');
                slider.classList.add('minimized');
                activeUrl = null;
                sliderFrame.src = 'about:blank';
                stopIframeWatch();
                hideBlocked();
            }
        }
    }

    function openSite(rawUrl, title) {
        const url = normalizeUrl(rawUrl);
        if (!url) return;
        
        // Always ensure the slider is in the right state before opening
        slider.classList.remove('minimized');
        
        // Create tab if it doesn't exist or reuse existing tab
        if (!tabs[url]) {
            createTab(url, title || url);
        } else {
            // If tab exists but was previously closed/minimized, ensure it's properly set up
            tabs[url].el.classList.add('active'); // Ensure tab is marked active
        }
        
        // Set as active tab and show content
        setActiveTab(url);
    }

    function closeSlider() {
        slider.classList.remove('open');
        slider.classList.add('minimized'); // Minimize instead of completely hiding
        sliderFrame.src = 'about:blank';
        activeUrl = null;
        stopIframeWatch();
        hideBlocked();
        // Ensure tab bar remains visible
        tabBar.style.display = 'flex';
    }

    // --- detect iframe going back to list (save complete) ---
    function isListLocation(href, doc) {
        if (!href && !doc) return false;
        try { if (href && /list_website_form/i.test(href)) return true; } catch { }
        try {
            if (doc) {
                if (doc.getElementById && (doc.getElementById('list_website_form') || doc.getElementById('dataList_list_website_form'))) return true;
            }
        } catch { }
        return false;
    }

    function startIframeWatch() {
        stopIframeWatch();
        sliderFrame.addEventListener('load', onIframeLoadHandler);
        iframePollId = setInterval(() => {
            try {
                const cw = sliderFrame.contentWindow;
                if (cw && isListLocation(cw.location.href, sliderFrame.contentDocument)) {
                    if (activeUrl) removeTab(activeUrl);
                    closeSlider();
                    refreshList(); // refresh outer list
                }
            } catch { }
        }, 500);
    }

    function stopIframeWatch() {
        sliderFrame.removeEventListener('load', onIframeLoadHandler);
        if (iframePollId) { clearInterval(iframePollId); iframePollId = null; }
    }

    function onIframeLoadHandler() {
        try {
            const href = sliderFrame.contentWindow.location.href;
            if (isListLocation(href, sliderFrame.contentDocument)) {
                if (activeUrl) removeTab(activeUrl);
                closeSlider();
                refreshList(); // refresh outer list
                return;
            }
            
            // We're using fixed tab names now, so no need to update titles
            
            hideBlocked();
        } catch {
            showBlocked(activeUrl || sliderFrame.src);
        }
    }

    // --- global click delegation ---
    document.addEventListener('click', function (ev) {
        // Skip if the click was on our own slider or tab bar
        if (ev.target.closest('#sideSlider, #tabBar')) return;
        
        // First, check if this is an "Edit using slider" button
        const sliderButton = ev.target.closest('a.btn.noAjax.no-close[onclick*="openSlider"]');
        if (sliderButton) {
            console.log('Edit using slider button clicked');
            ev.preventDefault();
            ev.stopPropagation();
            
            // Force reset all slider states
            slider.classList.remove('minimized');
            slider.classList.add('open');
            
            // Clear any previous active states
            if (activeUrl && tabs[activeUrl]) {
                tabs[activeUrl].el.classList.remove('active');
            }
            activeUrl = null;
            
            // Get the row and title information
            const row = sliderButton.closest('tr');
            const titleCell = row ? row.querySelector('td.column_website_title, td.body_column_0') : null;
            const title = titleCell ? titleCell.textContent.trim() : 'View';
            
            // Extract URL from the standard edit link in the same row
            const editLink = row ? row.querySelector('a.link_[href*="_mode=edit"]') : null;
            const href = editLink ? editLink.getAttribute('href') : '';
            
            if (href) {
                console.log('Opening slider with URL:', href);
                // Use a longer timeout to ensure DOM is fully ready
                setTimeout(() => {
                    openSite(href, 'Edit: ' + title);
                }, 100);
            }
            
            return false;
        }
        
        // Check if this is a standard Edit link - if so, let it behave normally
        const standardEditLink = ev.target.closest('a.link_[href*="_mode=edit"]');
        if (standardEditLink) {
            console.log('Standard edit link clicked - allowing default behavior');
            return true; // Allow default behavior for standard edit links
        }
        
        // For other buttons/links that match our criteria, use the slider
        const clickEl = ev.target.closest('a, button, [data-href]');
        if (!clickEl) return;
        
        const container = clickEl.closest('#list_website_form, #dataList_list_website_form, .dataList, form[name="form_list_website_form"], .table-wrapper');
        if (!container) return;
        
        let href = clickEl.tagName === 'A' ? clickEl.getAttribute('href') : clickEl.getAttribute('data-href');
        if (!href || !/_mode=(edit|add)/i.test(href)) return;
        
        // This is some other type of edit/add link or button (not the standard Edit link)
        console.log('Other edit/add link intercepted:', href);
        ev.preventDefault();
        ev.stopPropagation();
        
        // Force reset all slider states
        slider.classList.remove('minimized');
        slider.classList.add('open');
        
        // Clear any previous active states
        if (activeUrl && tabs[activeUrl]) {
            tabs[activeUrl].el.classList.remove('active');
        }
        activeUrl = null;
        
        const row = clickEl.closest('tr');
        const titleCell = row ? row.querySelector('td.column_website_title, td.body_column_0') : null;
        const title = titleCell ? titleCell.textContent.trim() : (clickEl.textContent || 'Form').trim();
        const humanTitle = /_mode=add/i.test(href) ? 'New: ' + title : 'Edit: ' + title;
        
        // Use a longer timeout to ensure DOM is fully ready
        setTimeout(() => {
            openSite(href, humanTitle);
        }, 100);
        
        return false;
    }, true);

    // --- tab bar ---
    tabBar.addEventListener('click', (e) => {
        const t = e.target.closest('.tab');
        if (t && t.dataset.url) setActiveTab(t.dataset.url);
    });

    // --- buttons ---
    document.getElementById('closeSlider').addEventListener('click', (e) => { 
        console.log('Close button clicked');
        e.preventDefault();
        e.stopPropagation();
        
        // Remove the current tab from the tab bar
        if (activeUrl && tabs[activeUrl]) {
            console.log('Removing tab for URL:', activeUrl);
            
            // Remove the tab element from the DOM
            if (tabs[activeUrl].el) {
                tabs[activeUrl].el.remove();
            }
            
            // Remove the tab from our tabs object
            delete tabs[activeUrl];
            
            // Hide the slider
            slider.classList.remove('open');
            slider.classList.add('minimized');
            
            // Reset active URL
            activeUrl = null;
            
            // Check if there are any remaining tabs
            const remainingTabs = Object.keys(tabs);
            if (remainingTabs.length > 0) {
                // If there are other tabs, activate the first one
                setTimeout(() => {
                    setActiveTab(remainingTabs[0]);
                }, 10);
            } else {
                // If no tabs remain, hide the slider and the tab bar
                sliderFrame.src = 'about:blank';
                tabBar.style.display = 'none';
                
                // Reset tab counter when all tabs are closed
                resetTabCounter();
            }
        } else {
            // No active URL, just hide the slider
            slider.classList.remove('open');
            slider.classList.add('minimized');
        }
        
        return false;
    });
    
    document.getElementById('minimizeSlider').addEventListener('click', (e) => {
        console.log('Minimize button clicked');
        e.preventDefault();
        e.stopPropagation();
        
        // Toggle minimized state but keep tabs intact
        slider.classList.toggle('minimized');
        
        // Make sure tabBar remains visible
        tabBar.style.display = 'flex';
        
        // Reset active state so new clicks will work
        if (slider.classList.contains('minimized') && activeUrl) {
            if (tabs[activeUrl] && tabs[activeUrl].el) {
                tabs[activeUrl].el.classList.remove('active');
            }
            activeUrl = null;
        }
        
        return false;
    });

    // Define global openSlider function for compatibility with existing code
    // This is the main entry point called from the Java code
    window.openSlider = function(url) {
        console.log('openSlider called with:', url);
        
        // Force reset all slider states to ensure it works properly
        slider.classList.remove('minimized');
        slider.classList.add('open');
        
        // Clear any previous active states
        if (activeUrl && tabs[activeUrl]) {
            tabs[activeUrl].el.classList.remove('active');
        }
        activeUrl = null;
        
        // Use a small timeout to ensure DOM is ready
        setTimeout(() => {
            openSite(url, 'View');
        }, 50);
        
        // Return false to prevent default link behavior
        return false;
    };
    
    // Keep track of tab count for numbering
    let tabCounter = 0;
    
    // Function to get the next tab number
    function getNextTabNumber() {
        tabCounter++;
        return tabCounter;
    }
    
    // Function to reset tab counter (useful if all tabs are closed)
    function resetTabCounter() {
        tabCounter = 0;
    }
    
    // Function to get tab name based on index
    function getTabName() {
        return 'Tab ' + getNextTabNumber();
    }
    
    // Function to attach click handlers to slider buttons
    function attachSliderHandlers() {
        console.log('Attaching slider handlers to buttons');
        document.querySelectorAll('a.btn.noAjax.no-close[onclick*="openSlider"]').forEach(function(btn) {
            // Remove any existing click handlers
            const newBtn = btn.cloneNode(true);
            btn.parentNode.replaceChild(newBtn, btn);
            
            // Add our custom click handler
            newBtn.onclick = function(e) {
                e.preventDefault();
                e.stopPropagation();
                
                // Force reset all slider states
                slider.classList.remove('minimized');
                slider.classList.add('open');
                
                // Get the row and title information
                const row = this.closest('tr');
                const titleCell = row ? row.querySelector('td.column_website_title, td.body_column_0') : null;
                const baseTitle = titleCell ? titleCell.textContent.trim() : 'View';
                
                // Extract URL from the standard edit link in the same row
                const editLink = row ? row.querySelector('a.link_[href*="_mode=edit"]') : null;
                const href = editLink ? editLink.getAttribute('href') : '';
                
                if (href) {
                    console.log('Opening slider with URL from custom handler:', href);
                    // Use a longer timeout to ensure DOM is fully ready
                    setTimeout(() => {
                        openSite(href, 'Edit: ' + baseTitle);
                    }, 100);
                }
                
                return false;
            };
        });
    }
    
    // Add page load event listener to ensure slider functionality works after page refreshes
    window.addEventListener('load', function() {
        console.log('Page loaded - reinitializing slider functionality');
        attachSliderHandlers();
        
        // Set up a mutation observer to watch for dynamically added content
        const observer = new MutationObserver(function(mutations) {
            mutations.forEach(function(mutation) {
                if (mutation.addedNodes && mutation.addedNodes.length > 0) {
                    // Check if any of the added nodes contain our slider buttons
                    for (let i = 0; i < mutation.addedNodes.length; i++) {
                        const node = mutation.addedNodes[i];
                        if (node.nodeType === 1 && (node.tagName === 'TR' || node.querySelector)) {
                            if (node.querySelector && node.querySelector('a.btn.noAjax.no-close[onclick*="openSlider"]')) {
                                console.log('Found dynamically added slider button - attaching handlers');
                                attachSliderHandlers();
                                break;
                            }
                        }
                    }
                }
            });
        });
        
        // Start observing the document with the configured parameters
        observer.observe(document.body, { childList: true, subtree: true });
    });
})();
</script>
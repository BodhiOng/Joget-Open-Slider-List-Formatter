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
    <div id="sliderFrames"></div>
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
{{ ... }}
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
  #sliderFrames { width: 100%; height: 100%; position: relative; }
  .slider-iframe { width: 100%; height: 100%; border: 0; position: absolute; top: 0; left: 0; display: none; }
  .slider-iframe.active { display: block; }
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
    
    // Debug function to check if elements exist
    function debugElements() {
        console.log('Slider exists:', !!document.getElementById('sideSlider'));
        console.log('SliderBody exists:', !!document.getElementById('sliderBody'));
        console.log('SliderFrames exists:', !!document.getElementById('sliderFrames'));
        console.log('SliderTitle exists:', !!document.getElementById('sliderTitle'));
        console.log('TabBar exists:', !!document.getElementById('tabBar'));
    }
    
    // Call debug function immediately
    debugElements();
    
    // --- Elements & state ---
    const slider = document.getElementById('sideSlider');
    const sliderBody = document.getElementById('sliderBody');
    const sliderFrames = document.getElementById('sliderFrames');
    const sliderTitle = document.getElementById('sliderTitle');
    const blockedNotice = document.getElementById('blockedNotice');
    const openNewTabBtn = document.getElementById('openNewTabBtn');
    const openPopupBtn = document.getElementById('openPopupBtn');
    const tabBar = document.getElementById('tabBar');
    
    // Check if elements were found
    if (!slider || !sliderBody || !sliderFrames || !sliderTitle || !tabBar) {
        console.error('Critical slider elements not found!');
    }

    // Multi-iframe tab management
    let tabs = {}; // Format: { url: { el: tabElement, title: string, iframe: iframeElement } }
    let activeUrl = null;
    let iframePollId = null;

    // --- helpers ---
    function normalizeUrl(raw) {
        console.log('normalizeUrl called with:', raw);
        if (!raw) {
            console.log('normalizeUrl: raw URL is null or empty');
            return null;
        }
        try { 
            const normalized = new URL(raw, window.location.origin).href;
            console.log('normalizeUrl: normalized to', normalized);
            return normalized; 
        }
        catch (e) { 
            console.error('normalizeUrl error:', e);
            return null; 
        }
    }
    
    // Function to save iframe state
    function saveIframeState(url) {
        if (!url || !sliderFrame.contentWindow) return false;
        
        try {
            console.log('Attempting to save iframe state for:', url);
            
            // Create a cache entry if it doesn't exist
            if (!iframeCache[url]) {
                iframeCache[url] = {
                    src: sliderFrame.src,
                    hasState: true
                };
            }
            
            return true;
        } catch (e) {
            console.error('Error saving iframe state:', e);
            return false;
        }
    }
    
    // Function to restore iframe state
    function restoreIframeState(url) {
        if (!url || !iframeCache[url]) return false;
        
        try {
            console.log('Restoring iframe state for:', url);
            
            // We don't need to do anything special here since we're not reloading the iframe
            // The iframe content is already preserved
            return true;
        } catch (e) {
            console.error('Error restoring iframe state:', e);
            return false;
        }
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
        // Hide all iframes
        Object.values(tabs).forEach(tab => {
            if (tab && tab.iframe) {
                tab.iframe.classList.remove('active');
            }
        });
        
        // Show blocked notice
        blockedNotice.style.display = 'flex';
        openNewTabBtn.onclick = () => window.open(url, '_blank', 'noopener');
        openPopupBtn.onclick = () => {
            const windowWidth = Math.min(window.innerWidth - 120, 1100);
            const windowHeight = Math.min(window.innerHeight - 120, 800);
            window.open(url, '_blank', 'width=' + windowWidth + ',height=' + windowHeight + ',left=50,top=50');
        };
    }
    
    function hideBlocked() {
        // Hide blocked notice
        blockedNotice.style.display = 'none';
        
        // Show active iframe if any
        if (activeUrl && tabs[activeUrl] && tabs[activeUrl].iframe) {
            tabs[activeUrl].iframe.classList.add('active');
        }
        
        // Clear button handlers
        openNewTabBtn.onclick = null;
        openPopupBtn.onclick = null;
    }

    function createTab(url, title) {
        if (tabs[url]) return;
        
        // Generate tab name based on index
        const tabName = getTabName();
        
        // Create tab element
        const tab = document.createElement('div');
        tab.className = 'tab';
        tab.dataset.url = url;
        tab.dataset.number = tabCounter; // Store the tab number for reference
        
        tab.innerHTML = '<span class="label">' + tabName + '</span><button class="closeTab">×</button>';
        tab.querySelector('.label').addEventListener('click', () => setActiveTab(url));
        tab.querySelector('.closeTab').addEventListener('click', (e) => { e.stopPropagation(); removeTab(url); });
        tabBar.appendChild(tab);
        
        // Create a dedicated iframe for this tab
        const iframe = document.createElement('iframe');
        iframe.className = 'slider-iframe';
        iframe.setAttribute('frameborder', '0');
        iframe.setAttribute('sandbox', 'allow-same-origin allow-scripts allow-forms allow-popups');
        sliderFrames.appendChild(iframe);
        
        // Store tab info with iframe reference
        tabs[url] = { 
            el: tab, 
            title: tabName, 
            number: tabCounter,
            iframe: iframe
        };
        
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
            // If we're already on this tab, do nothing
            if (activeUrl === url) {
                console.log('Already on this tab, doing nothing');
                return;
            }
            
            // Reset all tabs and iframes to inactive state
            Object.values(tabs).forEach(t => {
                if (t && t.el) t.el.classList.remove('active');
                if (t && t.iframe) t.iframe.classList.remove('active');
            });
            
            // Set this tab as active
            const tab = tabs[url];
            tab.el.classList.add('active');
            tab.iframe.classList.add('active');
            
            // Ensure slider is in the correct state - force it
            slider.style.display = 'flex';
            slider.classList.add('open');
            slider.classList.remove('minimized');
            
            // Update active URL and title
            activeUrl = url;
            
            // Set the slider title to the tab name
            sliderTitle.textContent = tab.title || 'View';
            
            // Reset content and start monitoring
            hideBlocked();
            
            // Check if this iframe has been loaded
            const isIframeLoaded = tab.iframe.src && tab.iframe.src !== 'about:blank';
            
            if (!isIframeLoaded) {
                // If this iframe hasn't been loaded yet, load the content
                console.log('Loading new content for tab:', url);
                tab.iframe.src = url;
            } else {
                console.log('Using existing iframe content for tab:', url);
                // The iframe already has content, no need to reload it
            }
            
            // Start monitoring the iframe
            startIframeWatch(tab.iframe);
            
            // Make sure tab bar is visible
            tabBar.style.display = 'flex';
        } catch (err) {
            console.error('Error in setActiveTab:', err);
        }
    }
    function removeTab(url) {
        if (!tabs[url]) return;
        const wasActive = (activeUrl === url);
        const tab = tabs[url];
        
        // Remove tab element
        tab.el.remove();
        
        // Remove iframe element
        if (tab.iframe) {
            console.log('Removing iframe for tab:', url);
            tab.iframe.remove();
        }
        
        // Remove from tabs object
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
        console.log('openSite called with:', rawUrl, title);
        const url = normalizeUrl(rawUrl);
        if (!url) {
            console.error('openSite: Failed to normalize URL, aborting');
            return;
        }
        
        // Always ensure the slider is in the right state before opening
        slider.classList.remove('minimized');
        slider.classList.add('open');
        
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
        
        // Don't reset activeUrl, we'll need it when restoring
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

    function startIframeWatch(iframe) {
        stopIframeWatch();
        
        // If no iframe is provided, use the active tab's iframe
        if (!iframe && activeUrl && tabs[activeUrl]) {
            iframe = tabs[activeUrl].iframe;
        }
        
        if (!iframe) {
            console.error('No iframe to watch');
            return;
        }
        
        // Add load event listener
        iframe.addEventListener('load', function(e) { onIframeLoadHandler(e, iframe); });
        
        // Start polling
        iframePollId = setInterval(() => {
            try {
                const cw = iframe.contentWindow;
                if (cw && isListLocation(cw.location.href, iframe.contentDocument)) {
                    // Instead of closing the slider and refreshing the entire list,
                    // we'll just refresh the current tab content with a success message
                    if (activeUrl) {
                        // Create a success message to display in the iframe
                        const successUrl = new URL(activeUrl, window.location.origin);
                        successUrl.searchParams.set('success', 'true');
                        
                        // Update the iframe with the success URL
                        iframe.src = successUrl.toString();
                        
                        // Refresh the list in the background without closing the slider
                        setTimeout(() => {
                            try {
                                const list = document.getElementById("list_website_form");
                                if (list && typeof list.refresh === "function") {
                                    list.refresh(); // Joget native refresh
                                }
                            } catch (e) { console.error(e); }
                        }, 1000);
                    }
                }
            } catch { }
        }, 500);
    }

    function stopIframeWatch() {
        // We don't need to remove event listeners since we'll be adding new ones
        if (iframePollId) { 
            clearInterval(iframePollId); 
            iframePollId = null; 
        }
    }

    function onIframeLoadHandler(event, iframe) {
        if (!iframe) {
            console.error('No iframe provided to onIframeLoadHandler');
            return;
        }
        
        try {
            const href = iframe.contentWindow.location.href;
            if (isListLocation(href, iframe.contentDocument)) {
                // Instead of closing the slider and refreshing the entire list,
                // we'll just refresh the current tab content with a success message
                if (activeUrl) {
                    // Create a success message to display in the iframe
                    const successUrl = new URL(activeUrl, window.location.origin);
                    successUrl.searchParams.set('success', 'true');
                    
                    // Update the iframe with the success URL
                    setTimeout(() => {
                        iframe.src = successUrl.toString();
                    }, 100);
                    
                    // Refresh the list in the background without closing the slider
                    setTimeout(() => {
                        try {
                            const list = document.getElementById("list_website_form");
                            if (list && typeof list.refresh === "function") {
                                list.refresh(); // Joget native refresh
                            }
                        } catch (e) { console.error(e); }
                    }, 1000);
                }
                return;
            }
            
            hideBlocked();
        } catch (e) {
            console.error('Error in onIframeLoadHandler:', e);
            if (activeUrl) {
                showBlocked(activeUrl);
            }
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
    });
    document.getElementById('minimizeSlider').addEventListener('click', (e) => {
        console.log('Minimize button clicked');
        e.preventDefault();
        e.stopPropagation();
        
        // Toggle minimized state but keep tabs intact
        slider.classList.toggle('minimized');
        
        // Make sure tabBar remains visible
        tabBar.style.display = 'flex';
        
        // When minimizing, we visually deactivate the tab but keep the activeUrl reference
        // This preserves the form state when minimized
        if (slider.classList.contains('minimized') && activeUrl) {
            if (tabs[activeUrl] && tabs[activeUrl].el) {
                tabs[activeUrl].el.classList.remove('active');
                
                // Save the iframe state in our cache when minimizing
                console.log('Saving iframe state on minimize for:', activeUrl);
                saveIframeState(activeUrl);
                
                // We intentionally do NOT set activeUrl to null here
                // This preserves the reference to the active tab
            }
        }
        
        return false;
    });

    // This is the main entry point called from the Java code
    window.openSlider = function(url) {
        console.log('openSlider called with:', url);
        
        // Force reset all slider states to ensure it works properly
        slider.classList.remove('minimized');
        slider.classList.add('open');
        
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
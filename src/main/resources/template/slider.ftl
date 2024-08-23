<!-- Slider Container -->
<div class="slider-container" id="slider">
  <div class="slider-handle"></div>
    <div class="slider-content">
    </div>
</div>

<style>
    

.slider-container {
    position: fixed;
    top: 0;
    right: -100%; /* Initially off-screen */
    width: ${width!};
    height: 100%;
    background-color: #fff;
    box-shadow: -2px 0 5px rgba(0, 0, 0, 0.5);
    transition: right 0.3s ease-in-out;
    overflow-y: auto; /* Enable vertical scrolling if content exceeds height */
    z-index: 9999;
    resize: horizontal;
}

.slider-handle {
  position: absolute;
  top: 0;
  left: 0;
  width: 10px;
  height: 100%;
  cursor: ew-resize; /* Horizontal resize cursor */
  background: #ddd; /* Optional, for visibility */
}

.slider-content {
    padding: 20px;
    height: 100%; /* Take full height of slider container */
    box-sizing: border-box; /* Ensure padding is included in height calculation */
}

.slider-container.open {
    right: 0;
}
</style>

<script>
    document.addEventListener('DOMContentLoaded', function() {
        closeSlider();
    });

    var slider = document.getElementById('slider');
    var sliderContent = document.querySelector('.slider-content');
    var handle = document.querySelector('.slider-handle');

    // enable resizing at left side of container
    let isResizing = false;
    let startX = 0;
    let startWidth = 0;

    // Mouse events
    handle.addEventListener('mousedown', startResize);
    document.addEventListener('mousemove', onResize);
    document.addEventListener('mouseup', stopResize);

    // Touch events
    handle.addEventListener('touchstart', startResize);
    document.addEventListener('touchmove', onResize);
    document.addEventListener('touchend', stopResize);

    function startResize(e) {
        isResizing = true;
        startX = e.type === 'touchstart' ? e.touches[0].clientX : e.clientX;
        startWidth = slider.clientWidth;
        e.preventDefault();
    }

    function onResize(e) {
    if (!isResizing) return;
        const currentX = e.type === 'touchmove' ? e.touches[0].clientX : e.clientX;
        const deltaX = currentX - startX;
        slider.style.width = (startWidth - deltaX) + 'px';
        e.preventDefault();
    }

    function stopResize() {
        isResizing = false;
    }

    // Function to open the slider
    function openSlider(url) {
        //console.log("opening" + url);
        closeSlider();

        // Clear previous content if any
        sliderContent.innerHTML = '';
        
        // Create an iframe to load the external content
        var iframe = document.createElement('iframe');
        iframe.src = url;
        iframe.style.width = '100%';
        iframe.style.height = '100%'; // Take full height of slider content area
        iframe.style.border = 'none';
        
        // Append the iframe to slider content
        sliderContent.appendChild(iframe);
        
        slider.classList.add('open');
        
        // Add event listener to close slider when clicking outside
        setTimeout("document.addEventListener('click', clickOutsideHandler)", 500);
    }

    // Function to close the slider
    function closeSlider() {
        //console.log("closing");
        sliderContent.innerHTML = ''; // Clear iframe content
        slider.classList.remove('open');
        
        // Remove event listener for clicking outside
        document.removeEventListener('click', clickOutsideHandler);
    }

    // Event listener for clicking outside the slider
    function clickOutsideHandler(e) {
        if (!slider.contains(e.target)) {
            closeSlider();
        }
    }

</script>
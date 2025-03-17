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

.slider-handle {
    touch-action: none; /* Prevents default scrolling during resize */
}

</style>

<script>
   document.addEventListener('DOMContentLoaded', function () {
        closeSlider();
    });

    var slider = document.getElementById('slider');
    var sliderContent = document.querySelector('.slider-content');
    var handle = document.querySelector('.slider-handle');

    var isResizing = false;
    var startX = 0;
    var startWidth = 0;

    // Use pointer events for better tracking
    handle.addEventListener('pointerdown', startResize);
    document.addEventListener('pointermove', onResize);
    document.addEventListener('pointerup', stopResize);
    document.addEventListener('pointerleave', stopResize); // Handle cases where the pointer leaves the document

    function startResize(e) {
        isResizing = true;
        startX = e.clientX;
        startWidth = slider.clientWidth;
        handle.setPointerCapture(e.pointerId); // Ensures the handle keeps receiving pointer events
        e.preventDefault();
    }

    function onResize(e) {
        if (!isResizing) return;
        const currentX = e.clientX;
        const deltaX = currentX - startX;
        slider.style.width = (startWidth - deltaX) + 'px';
    }

    function stopResize(e) {
        isResizing = false;
        handle.releasePointerCapture(e.pointerId); // Release the pointer capture
    }

    // Function to open the slider
    function openSlider(url) {
        closeSlider();
        sliderContent.innerHTML = '';

        var iframe = document.createElement('iframe');
        iframe.src = url;
        iframe.style.width = '100%';
        iframe.style.height = '100%';
        iframe.style.border = 'none';

        sliderContent.appendChild(iframe);
        slider.classList.add('open');
    }

    // Function to close the slider
    function closeSlider() {
        sliderContent.innerHTML = '';
        slider.classList.remove('open');
    }

    // Click outside to close
    document.addEventListener('click', function (e) {
        if (slider.classList.contains('open') && !slider.contains(e.target) && !e.target.closest('.no-close')) {
            closeSlider();
        }
    });

</script>
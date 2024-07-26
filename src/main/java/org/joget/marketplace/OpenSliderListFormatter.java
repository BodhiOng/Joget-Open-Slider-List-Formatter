package org.joget.marketplace;

import java.net.URLEncoder;
import java.util.HashMap;
import javax.servlet.http.HttpServletRequest;
import org.joget.apps.app.service.AppPluginUtil;
import org.joget.apps.app.service.AppUtil;
import org.joget.apps.form.model.FormRow;
import org.joget.apps.datalist.model.DataList;
import org.joget.apps.datalist.model.DataListColumn;
import org.joget.apps.datalist.model.DataListColumnFormatDefault;
import org.joget.apps.datalist.service.DataListService;
import org.joget.workflow.util.WorkflowUtil;

public class OpenSliderListFormatter extends DataListColumnFormatDefault  {
    
    private final static String MESSAGE_PATH = "messages/OpenSliderListFormatter";

    @Override
    public String getName() {
        return AppPluginUtil.getMessage("org.joget.marketplace.OpenSliderListFormatter.pluginLabel", getClassName(), MESSAGE_PATH);
    }

    @Override
    public String getVersion() {
        return "8.0.0";
    }
    
    @Override
    public String getClassName() {
        return getClass().getName();
    }
    
    @Override
    public String getLabel() {
        //support i18n
        return AppPluginUtil.getMessage("org.joget.marketplace.OpenSliderListFormatter.pluginLabel", getClassName(), MESSAGE_PATH);
    }
    
    @Override
    public String getDescription() {
        //support i18n
        return AppPluginUtil.getMessage("org.joget.marketplace.OpenSliderListFormatter.pluginDesc", getClassName(), MESSAGE_PATH);
    }

    @Override
    public String getPropertyOptions() {
        return AppUtil.readPluginResource(getClassName(), "/properties/OpenSliderListFormatter.json", null, true, MESSAGE_PATH);
    }
    
//    protected String getValue(Object row, String columnName) {
//        String paramValue = "";
//        
//        try {
//            paramValue = (String) ((HashMap)row).get(columnName);
//            return (paramValue != null) ? URLEncoder.encode(paramValue, "UTF-8") : null;
//        } catch (Exception ex) {
//            return "";
//        }
//    }
    
    public String getHref() {
        return getPropertyString("href");
    }
    
    public String getHrefParam() {
        return getPropertyString("hrefParam");
    }

    public String getHrefColumn() {
        return getPropertyString("hrefColumn");
    }
    
    public String getLinkLabel() {
        String label = getPropertyString("label");
        if (label == null || label.isEmpty()) {
            label = "Hyperlink";
        }
        return label;
    }

    @Override
    public String format(DataList dataList, DataListColumn dlc, Object row, Object value) {
        String content = "";
        HttpServletRequest request = WorkflowUtil.getHttpServletRequest();
        
        if (request != null && request.getAttribute(getClassName()) == null) {
            content += "<!-- Slider Container -->\n" +
                        "<div class=\"slider-container\" id=\"slider\">\n" +
                        "    <div class=\"slider-content\">\n" +
                        "    </div>\n" +
                        "</div>\n" +
                        "\n" +
                        "<style>\n" +
                        "    \n" +
                        "\n" +
                        ".slider-container {\n" +
                        "    position: fixed;\n" +
                        "    top: 0;\n" +
                        "    right: -100%; /* Initially off-screen */\n" +
                        "    width: 40%; /* Adjust as needed */\n" +
                        "    height: 100%;\n" +
                        "    background-color: #fff;\n" +
                        "    box-shadow: -2px 0 5px rgba(0, 0, 0, 0.5);\n" +
                        "    transition: right 0.3s ease-in-out;\n" +
                        "    overflow-y: auto; /* Enable vertical scrolling if content exceeds height */\n" +
                        "    z-index: 9999;\n" +
                        "}\n" +
                        "\n" +
                        ".slider-content {\n" +
                        "    padding: 20px;\n" +
                        "    height: 100%; /* Take full height of slider container */\n" +
                        "    box-sizing: border-box; /* Ensure padding is included in height calculation */\n" +
                        "}\n" +
                        "\n" +
                        ".slider-container.open {\n" +
                        "    right: 0;\n" +
                        "}\n" +
                        "</style>\n" +
                        "\n" +
                        "<script>\n" +
                        "    document.addEventListener('DOMContentLoaded', function() {\n" +
                        "        closeSlider();\n" +
                        "    });\n" +
                        "\n" +
                        "    var openSliderBtn = document.getElementById('open-slider');\n" +
                        "    var closeSliderBtn = document.getElementById('close-slider');\n" +
                        "    var slider = document.getElementById('slider');\n" +
                        "    var sliderContent = document.querySelector('.slider-content');\n" +
                        "\n" +
                        "    // Function to open the slider\n" +
                        "    function openSlider(url) {\n" +
                        "        console.log(\"opening\" + url);\n" +
                        "        \n" +
                        "        // Clear previous content if any\n" +
                        "        sliderContent.innerHTML = '';\n" +
                        "        \n" +
                        "        // Create an iframe to load the external content\n" +
                        "        var iframe = document.createElement('iframe');\n" +
                        "        iframe.src = url;\n" +
                        "        iframe.style.width = '100%';\n" +
                        "        iframe.style.height = '100%'; // Take full height of slider content area\n" +
                        "        iframe.style.border = 'none';\n" +
                        "        \n" +
                        "        // Append the iframe to slider content\n" +
                        "        sliderContent.appendChild(iframe);\n" +
                        "        \n" +
                        "        slider.classList.add('open');\n" +
                        "        \n" +
                        "        // Add event listener to close slider when clicking outside\n" +
                        "        document.addEventListener('click', clickOutsideHandler);\n" +
                        "    }\n" +
                        "\n" +
                        "    // Function to close the slider\n" +
                        "    function closeSlider() {\n" +
                        "        console.log(\"closing\");\n" +
                        "        sliderContent.innerHTML = ''; // Clear iframe content\n" +
                        "        slider.classList.remove('open');\n" +
                        "        \n" +
                        "        // Remove event listener for clicking outside\n" +
                        "        document.removeEventListener('click', clickOutsideHandler);\n" +
                        "    }\n" +
                        "\n" +
                        "    // Event listener for clicking outside the slider\n" +
                        "    function clickOutsideHandler(e) {\n" +
                        "        eClass = \"\";\n" +
                        "        eClasses = [];\n" +
                        "        try{\n" +
                        "            eClass = e.target.attributes.getNamedItem(\"class\").value;\n" +
                        "            eClasses = eClass.split(\" \");\n" +
                        "        }catch(e){\n" +
                        "            \n" +
                        "        }\n" +
                        "        console.log( eClasses.indexOf(\"openSlider\") );\n" +
                        "        if (!slider.contains(e.target) && e.target !== openSliderBtn && eClasses.indexOf(\"openSlider\") < 0) {\n" +
                        "            closeSlider();\n" +
                        "        }\n" +
                        "    }\n" +
                        "\n" +
                        "</script>";
            request.setAttribute(getClassName(), true);
        }
        
        String url = getHref();
        String hrefParam = getHrefParam();
        String hrefColumn = getHrefColumn();
        
        if (hrefParam != null && hrefColumn != null && !hrefColumn.isEmpty()) {
            //DataListCollection rows = dataList.getRows();
            //String primaryKeyColumnName = dataList.getBinder().getPrimaryKeyColumnName();
        
            String[] params = hrefParam.split(";");
            String[] columns = hrefColumn.split(";");

            for (int i = 0; i < columns.length; i++) {
                if (columns[i] != null && !columns[i].isEmpty()) {
                    boolean isValid = false;
                    if (params.length > i && params[i] != null && !params[i].isEmpty()) {
                        if (url.contains("?")) {
                            url += "&";
                        } else {
                            url += "?";
                        }
                        url += params[i];
                        url += "=";
                        isValid = true;
                    } else if (!url.contains("?")) {
                        if (!url.endsWith("/")) {
                            url += "/";
                        }
                        isValid = true;
                    }

                    if (isValid) {
                        String val = DataListService.evaluateColumnValueFromRow(row, columns[i]).toString();
                        url += val + ";";
                        //url += getValue(row, columns[i]) + ";";
                        url = url.substring(0, url.length() - 1);
                    }
                }
            }
        }
        
        return content + "<span class=\"openSlider btn btn-sm btn-primary\" onClick=\"openSlider('"+ url +"')\">" + getLinkLabel() + "</span>";
    }
}

package org.joget.marketplace;

import java.util.HashMap;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import javax.servlet.http.HttpServletRequest;
import org.joget.apps.app.service.AppPluginUtil;
import org.joget.apps.app.service.AppUtil;
import org.joget.apps.datalist.model.DataList;
import org.joget.apps.datalist.model.DataListColumn;
import org.joget.apps.datalist.model.DataListColumnFormatDefault;
import org.joget.apps.datalist.service.DataListService;
import org.joget.plugin.base.PluginManager;
import org.joget.workflow.util.WorkflowUtil;

public class OpenSliderListFormatter extends DataListColumnFormatDefault {

    private final static String MESSAGE_PATH = "messages/OpenSliderListFormatter";

    @Override
    public String getName() {
        return AppPluginUtil.getMessage("org.joget.marketplace.OpenSliderListFormatter.pluginLabel", getClassName(), MESSAGE_PATH);
    }

    @Override
    public String getVersion() {
        return "8.0.4";
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

    public String getHref() {
        return getPropertyString("href");
    }

    public String getHrefParam() {
        return getPropertyString("hrefParam");
    }

    public String getHrefColumn() {
        return getPropertyString("hrefColumn");
    }

    public String getLinkLabel(DataList dataList, Object row, Object value) {
        String label = getPropertyString("label");

        if (label != null && !label.isEmpty()) {
            Pattern pattern = Pattern.compile("\\{([^\\}]+)\\}");
            Matcher matcher = pattern.matcher(label);

            if (!matcher.find()) {
                return label;
            }

            matcher.reset();
            StringBuffer processedLabel = new StringBuffer();

            while (matcher.find()) {
                String columnName = matcher.group(1);
                Object columnValue = DataListService.evaluateColumnValueFromRow(row, columnName);
                String replacement;

                if (columnValue != null && !columnValue.toString().trim().isEmpty()) {
                    replacement = columnValue.toString();
                } else if (value != null && !value.toString().trim().isEmpty()) {
                    // Use current column value as fallback
                    replacement = value.toString();
                } else {
                    // Final fallback
                    replacement = "Hyperlink";
                }

                matcher.appendReplacement(processedLabel, Matcher.quoteReplacement(replacement));
            }

            matcher.appendTail(processedLabel);

            String finalLabel = processedLabel.toString().trim();
            return finalLabel.isEmpty() ? "Hyperlink" : finalLabel;
        } else if (value != null && !value.toString().trim().isEmpty()) {
            return value.toString();
        } else {
            return "Hyperlink";
        }
    }

    @Override
    public String format(DataList dataList, DataListColumn dlc, Object row, Object value) {
        String content = "";
        HttpServletRequest request = WorkflowUtil.getHttpServletRequest();

        // Only inject the template once per request
        if (request != null && request.getAttribute(getClassName()) == null) {
            PluginManager pluginManager = (PluginManager) AppUtil.getApplicationContext().getBean("pluginManager");
            Map model = new HashMap();
            model.put("element", this);
            if (getPropertyString("width") != null) {
                model.put("width", getPropertyString("width"));
            } else {
                model.put("width", "50%");
            }

            content += pluginManager.getPluginFreeMarkerTemplate(model, getClass().getName(), "/template/slider.ftl", null);
            request.setAttribute(getClassName(), true);
        }

        // Get the URL directly from the href property
        String url = getHref();
        
        // Apply basic styling
        String displayStyle = getProperty("link-css-display-type").toString();
        displayStyle += " noAjax no-close";

        // Return the link with the openSlider function
        // Use return false to prevent default link behavior
        return content + "<a class=\"" + displayStyle + "\" onClick=\"return openSlider('" + url + "')\" href=\"javascript:void(0);\">" + getLinkLabel(dataList, row, value) + "</a>";
    }
}

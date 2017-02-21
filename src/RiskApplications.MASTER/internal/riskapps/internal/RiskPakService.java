package riskapps.internal;

import java.util.List;

import com.olf.embedded.application.Context;
import com.olf.openrisk.io.QueryResult;
import com.olf.openrisk.trading.Transactions;

/**
 * @author tbain
 * @version 3.1, July 12, 2012
 */
public class RiskPakService {
	/**
	 * Controls whether or not the RiskPak Configuration Popup GUI Screen will
	 * appear <br />
	 * <br />
	 * <b>*** Must be called from {@link #initPopUpSettings()} *** </b>
	 * 
	 * @param bShow
	 */
	public final void showConfigPopup(boolean bShow) {
	}

	/**
	 * Adds a Report Type to the Filter that will be used in the RiskPak
	 * Configuration Popup GUI Screen <br />
	 * <br />
	 * <b>*** Must be called from {@link #initPopUpSettings()} *** </b> <br />
	 * <br />
	 * <b>NOTE: Only Query-Based Reports will appear in the Filtered List </b>
	 * 
	 * @param reportType
	 *            Single Report Type to be added to the List of Reports to
	 *            Filter by
	 */
	public final void addReportTypeFilter(String reportType) {
	}

	/**
	 * Overrides the Report Types Filter that will be used in the RiskPak
	 * Configuration Popup GUI Screen <br />
	 * <br />
	 * <b>*** Must be called from {@link #initPopUpSettings()} *** </b> <br />
	 * <br />
	 * <b>NOTE: Only Query-Based Reports will appear in the Filtered List</b>
	 * 
	 * @param reportTypes
	 *            List of Reports to Filter by
	 */
	public final void setReportTypeFilter(List<String> reportTypes) {
	}

	/**
	 * Resets the Report Type Filter in the RiskPak Configuration Popup GUI
	 * Screen so that all Report Types are available <br />
	 * <br />
	 * <b>*** Must be called from {@link #initPopUpSettings()} *** </b>
	 */
	public final void clearReportTypeFilter() {
	}

	/**
	 * This function must be overridden in order to Suppress the RiskPak
	 * Configuration Popup GUI or Apply Report Type Filters
	 */
	public void initPopUpSettings() {
	}

	public void executeRiskPakReport(Context context, int iCfgId,
			Transactions transactions) {
	}

	public void executeRiskPakReport(Context context, int iCfgId,
			QueryResult qryResult) {
	}

	public String executeRiskPakReport(Context context, int iCfgId, int iQryId,
			boolean bDesktop) {
		return null;
	}
}

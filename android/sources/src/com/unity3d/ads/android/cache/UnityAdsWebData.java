package com.unity3d.ads.android.cache;

import java.util.ArrayList;

import org.json.JSONArray;
import org.json.JSONObject;

import android.util.Log;

import com.unity3d.ads.android.UnityAdsProperties;
import com.unity3d.ads.android.UnityAdsUtils;
import com.unity3d.ads.android.campaign.UnityAdsCampaign;

public class UnityAdsWebData {
	private JSONObject _videoPlan = null;
	private ArrayList<UnityAdsCampaign> _videoPlanCampaigns = null;
	
	public UnityAdsWebData () {
		
	}
	
	public ArrayList<UnityAdsCampaign> getVideoPlanCampaigns () {
		return _videoPlanCampaigns;
	}
	
	public int getCampaignAmount () {
		if (_videoPlanCampaigns == null) return 0;
		return _videoPlanCampaigns.size();
	}
	
	public UnityAdsCampaign getCampaignById (String campaignId) {
		for (UnityAdsCampaign currentCampaign : _videoPlanCampaigns) {
			if (currentCampaign.getCampaignId().equals(campaignId))
				return currentCampaign;
		}
		
		return null;
	}
	
	public boolean initVideoPlan (ArrayList<String> cachedCampaignIds) {		
		JSONObject data = new JSONObject();
		JSONArray campaignIds = null;
		
		if (cachedCampaignIds != null && cachedCampaignIds.size() > 0) {
			campaignIds = new JSONArray();
			
			for (String id : cachedCampaignIds) {
				campaignIds.put(id);
			}
		}
		
		try {
			data.put("c", campaignIds);
		}
		catch (Exception e) {
			Log.d(UnityAdsProperties.LOG_NAME, "Malformed JSON");
			return false;
		}
		
		String cachedCampaignData = null;
		
		if (data != null && campaignIds != null && campaignIds.length() > 0) {
			cachedCampaignData = data.toString();
			Log.d(UnityAdsProperties.LOG_NAME, cachedCampaignData);
		}
					
		// TODO: Send campaign ID's with the request
		
		/*
		URL yahoo = new URL("http://www.yahoo.com/");
		BufferedReader in = new BufferedReader(
		            new InputStreamReader(
		            yahoo.openStream()));

		String inputLine;

		while ((inputLine = in.readLine()) != null)
		    System.out.println(inputLine);

		in.close();*/
		
		JSONArray videos = new JSONArray();
		JSONObject tmpvideo = null;
		
		try {
			/*
			tmpvideo = new JSONObject();
			tmpvideo.put("v", "http://quake.everyplay.fi/~bluesun/testvideos/video4.mp4");
			tmpvideo.put("s", "Ready");
			tmpvideo.put("id", "a4");
			videos.put(tmpvideo);
			*/
			
			tmpvideo = new JSONObject();
			tmpvideo.put("v", "http://quake.everyplay.fi/~bluesun/testvideos/video5.mp4");
			tmpvideo.put("s", "Ready");
			tmpvideo.put("id", "a5");
			videos.put(tmpvideo);
			
			tmpvideo = new JSONObject();
			tmpvideo.put("v", "http://quake.everyplay.fi/~bluesun/testvideos/video2.mp4");
			tmpvideo.put("s", "blaa2");
			tmpvideo.put("id", "a2");
			videos.put(tmpvideo);
	
			/*
			tmpvideo = new JSONObject();
			tmpvideo.put("v", "http://quake.everyplay.fi/~bluesun/testvideos/video5.mp4");
			tmpvideo.put("s", "blaa3");
			tmpvideo.put("id", "a3");
			videos.put(tmpvideo);			
			*/
			
			_videoPlan = new JSONObject();
			_videoPlan.put("va", videos);
			
			Log.d(UnityAdsProperties.LOG_NAME, _videoPlan.toString(4));
			
			_videoPlanCampaigns = UnityAdsUtils.createCampaignsFromJson(_videoPlan);
		}
		catch (Exception e) {
			Log.d(UnityAdsProperties.LOG_NAME, "Great error!");
			return false;
		}
		
		return true;
	}
}

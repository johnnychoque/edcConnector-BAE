/*
 *  Copyright (c) 2024 Universidad de Cantabria (UC)
 *
 *  This program and the accompanying materials are made available under the
 *  terms of the Apache License, Version 2.0 which is available at
 *  https://www.apache.org/licenses/LICENSE-2.0
 *
 *  SPDX-License-Identifier: Apache-2.0
 *
 *  Contributors:
 *       Johnny Choque (UC)
 *
 */

package org.eclipse.edc.sample.extension.event;

import com.fasterxml.jackson.databind.ObjectMapper;
import okhttp3.MediaType;
import okhttp3.Request;
import okhttp3.RequestBody;
import org.eclipse.edc.http.spi.EdcHttpClient;
import org.eclipse.edc.spi.event.Event;
import org.eclipse.edc.spi.event.EventEnvelope;
import org.eclipse.edc.spi.event.EventSubscriber;

import java.io.IOException;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

/**
 * Event subscriber that will send a notification to edcUser App when a EDC event is detected.
 */
public class NotifyToEdcUserApp implements EventSubscriber {
    private final EdcHttpClient httpClient;

    NotifyToEdcUserApp(EdcHttpClient httpClient) {
        this.httpClient = httpClient;
    }

    @Override
    public <E extends Event> void on(EventEnvelope<E> event) {
        var payload = event.getPayload();
        List<String> dspEvents = Arrays.asList("ContractNegotiationVerified", "ContractNegotiationFinalized", "TransferProcessInitiated", "TransferProcessStarted");

        if (dspEvents.contains(payload.getClass().getSimpleName())) {
            System.out.println(">>>>>>>>>>>>>> EVENT >>>>>>>>>>>>>");
            System.out.println(payload.toString());
            sendNotification(payload.getClass().getSimpleName());
        } else {
            System.out.println("---- DSP EVENT NOT INCLUDED---");
            System.out.println(payload.toString());
        }
        
    }

    private void sendNotification(String eventType) {
        final MediaType jsonSetting = MediaType.get("application/json; charset=utf-8");
        final String url = "http://localhost:9010/event/updatestatus";
        
        final ObjectMapper mapper = new ObjectMapper();
        try {
            String jsonBody = mapper.writeValueAsString(Map.of("event", eventType));
            RequestBody body = RequestBody.create(jsonBody, jsonSetting);

            var request = new Request.Builder()
                    .url(url)
                    .post(body)
                    .build();

            var response = httpClient.execute(request);
            if (!response.isSuccessful()) {
                throw new IOException("Unexpected code " + response);
            }
            System.out.println(response.body().string());
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
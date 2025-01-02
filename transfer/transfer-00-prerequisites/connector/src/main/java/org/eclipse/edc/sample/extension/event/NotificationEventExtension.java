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

import org.eclipse.edc.http.spi.EdcHttpClient;
import org.eclipse.edc.runtime.metamodel.annotation.Inject;
import org.eclipse.edc.spi.event.Event;
import org.eclipse.edc.spi.event.EventRouter;
import org.eclipse.edc.spi.system.ServiceExtension;
import org.eclipse.edc.spi.system.ServiceExtensionContext;
 
public class NotificationEventExtension implements ServiceExtension {
    @Inject
    private EdcHttpClient httpClient;

    @Inject
    private EventRouter eventRouter;

    @Override
    public void initialize(ServiceExtensionContext context) {
        //eventRouter.register(Event.class, new ExampleEventSubscriber()); // asynchronous dispatch
        eventRouter.registerSync(Event.class, new NotifyToEdcUserApp(httpClient)); // synchronous dispatch
    }
}
 
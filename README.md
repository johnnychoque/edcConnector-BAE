# EDC connector used in FIWARE BAE

This repository contains the EDC connector used for the integration of the dataspaces into the FIWARE BAE marketplace. The implemented connector is based on the code provided in the Eclipse EDC [Transfer Samples repository](https://github.com/eclipse-edc/Samples/blob/main/transfer). It only focuses on the **Consumer Pull** use case, so all other code not related to that use case has been removed.

## Connector extension

In order to capture EDC events that occur in the connector during interaction with other connectors, a **NotificationEventExtension** has been created in the directory `transfer/transfer-00-prerequisites/connector/src/main/java/org/eclipse/edc/sample/extension/event`. Within this extension the synchronous event **NotifyToEdcUserApp** has been defined. This custom event detects all EDC events that occur during the interaction between connectors. For the integration of the data spaces in the FIWARE BAE marketplace, only the following EDC events need to be detected: 

- ContractNegotiationVerified
- ContractNegotiationFinalized
- TransferProcessInitiated
- TransferProcessStarted

When one of these EDC events is detected, a notification is sent to the backend of the edcUser App with the name of the EDC event that has been detected.

## Usage

Build the connector using the following command:
```bash
./gradlew transfer:transfer-00-prerequisites:connector:build
```

Use the following command to run a connector for each user (Consumer and Provider) at the same time:
```bash
$ ./edc-connector.sh start both
```
Use the following commands in different terminals to see if the connectors are running correctly:
```bash
$ tail -f /tmp/provider.log
$ tail -f /tmp/consumer.log
```

To stop the execution of the connectors use the command:
```bash
$ ./edc-connector.sh stop both
```

Sometimes the edc-connector script fails to stop the connector. In that case, find the PID of the connector using the command:
```bash
$ ps ax | grep <provider or consumer>
```
and then kill the process with the command:
```bash
$ sudo kill <pid>
```
@RestResource(urlMapping='/v1/cars')
global without sharing class RestCars {

    @HttpPost
    global static void doCreate() {

        List<Map<String, Object>> response = new List<Map<String, Object>>();

        String payload = RestContext.request.requestBody.toString();

        List<CarModel> cars;

        try {
            cars = (List<CarModel>) JSON.deserialize(payload, List<CarModel>.class);
        }
        catch(Exception exc) {
            setResponseStatusCode(400);
            return;
        }

        Set<String> producersName = new Set<String>();
        Map<String, Id> obtainProducerByName = new Map<String, Id>();

        for (CarModel car : cars) {
            producersName.add(car.fabricante);
        }
        

        for (Account account : [SELECT Id, Name FROM Account WHERE Name IN: producersName]) {
            obtainProducerByName.put(account.Name, account.Id);
        }        

        List<Carro__c> cars2Save = new List<Carro__c>();

        for (CarModel car : cars) {
            Carro__c carLine = new Carro__c();

            if (!obtainProducerByName.containsKey(car.fabricante)) {
                response.add(
                    new Map<String, Object>{
                        'placa' => car.placa,
                        'status' => false,
                        'message' => String.format('Fabricante {0} não encontrada! Solicite o cadastro!', new List<String>{car.fabricante})
                    }
                );
                continue;
            }

            carLine.Chassi__c = car.chassi;
            carLine.Combustivel__c = car.combustivel;
            carLine.Renavam__c = car.renavam;
            carLine.Cor__c = car.cor;
            carLine.Modelo__c = car.modelo;
            carLine.Fabricante__c = obtainProducerByName.get(car.fabricante);
            carLine.Placa__c = car.placa;
            carLine.SituacaoVeiculo__c = car.situacaoVeiculo;
            carLine.Quilometragem__c = car.quilometragem;

            cars2Save.add(carLine);
        }


        List<Database.UpsertResult> saveCars = Database.upsert(cars2Save, Carro__c.Placa__c, false);

        for (Integer i = 0; i < cars2Save.size(); i++) {
            response.add(
                new Map<String, Object>{
                    'placa' => cars2Save[i].Placa__c,
                    'status' => saveCars[i].isSuccess(),
                    'id' => saveCars[i].getId(),
                    'isNew' => saveCars[i].isCreated()
                }
            );
        }

        setResponseBody(response);

    }

    private static void setResponseStatusCode(Integer statusCode) {

        if (statusCode == null)
            return;

        RestContext.response.statusCode = statusCode;
    }

    private static void setResponseBody(Object response) {
        
        if (response == null)
            return;

        RestContext.response.responseBody = Blob.valueOf(JSON.serializePretty(response));
        RestContext.response.addHeader('Content-Type', 'application/json');
    }

    
}
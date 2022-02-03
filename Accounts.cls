public with sharing class Accounts {
    
    //Pegar o Id do tipo de registro pelo "Developer Name" dá uma garantia maior.
    // Alterar um rótulo pode ser algo frequente, já o nome de API não.
    // O Código apresenta chamadas ao banco dentro de um laço de repetição
    // Os limites por thread de SOQL e DML podem ser atingidos
    // Coloquei mais duas formas de alcançar o objetivo do método apresentado

    public static void updateTotalCases() {

        

        Id customerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('Customer').getRecordTypeId();

        List<Account> accounts = [SELECT Id FROM Account WHERE RecordTypeId =: customerRecordTypeId];
        List<Case> cases = [SELECT Id, AccountId FROM Case WHERE AccountId IN: accounts];

        Map<Id, List<Case>> obtainCasesByAccountId = new Map<Id, List<Case>>();

        for (Case caseLine : cases) {
            List<Case> aux = new List<Case>();
            
            if (obtainCasesByAccountId.containsKey(caseLine.AccountId)) {
                aux = obtainCasesByAccountId.get(caseLine.AccountId);
            }

            aux.add(caseLine);
            
            obtainCasesByAccountId.put(caseLine.AccountId, aux);
        }

        for (Account account : accounts) {

            account.TotalCasos__c = 0;

            if (obtainCasesByAccountId.containsKey(account.Id)) {
                account.TotalCasos__c = obtainCasesByAccountId.get(account.Id).size();
            }
        }

        update accounts;
    }

    public static void updateTotalCases2() {

        Id customerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('Customer').getRecordTypeId();

        List<Account> accounts = [SELECT Id, (SELECT Id FROM Cases) FROM Account WHERE RecordTypeId =: customerRecordTypeId];

        for (Account account : accounts) {
            account.TotalCasos__c = account.Cases.size();
        }

        update accounts;
    }

    public static void updateTotalCases3() {

        Id customerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('Customer').getRecordTypeId();

        List<Account> accounts = new List<Account>();

        List<AggregateResult> results = [SELECT COUNT(Id) total, AccountId accountId FROM Case WHERE Account.RecordTypeId =:customerRecordTypeId GROUP BY AccountId];

        for (AggregateResult result : results) {
            accounts.add(
                new Account(
                    Id = (Id) result.get('accountId'),
                    TotalCasos__c = (Integer) result.get('total')
                )
            );
        }

        update accounts;
    }
}

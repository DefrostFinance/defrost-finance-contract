module.exports = class eventDecoder {
    constructor(){
        this.eventsMap = {}
    }
    async initEventsMap(abis){
        for (var i=0;i<abis.length;i++){
            let contract = await new web3.eth.Contract(abis[i]);
            for (var j=0;j<contract._jsonInterface.length;j++){
                if(contract._jsonInterface[j].type == "event"){
                    this.eventsMap[contract._jsonInterface[j].signature] = contract._jsonInterface[j];
                }
            }
        }
    }
    decodeEvent(log){
        if(this.eventsMap.hasOwnProperty(log.topics[0])){
            let result = web3.eth.abi.decodeLog(this.eventsMap[log.topics[0]].inputs,log.data,log.topics.slice(1));
            return [this.eventsMap[log.topics[0]].name,result];
        }else{
            //console.log("event not find :",log)
        }
    }
    decodeTxEvents(receipt){
        let events = []
        for (var i=0;i<receipt.receipt.rawLogs.length;i++){
            let result = this.decodeEvent(receipt.receipt.rawLogs[i]);
            if(result && result.length > 1){
                events.push(result);
            }
        }
        return events;
    }
}
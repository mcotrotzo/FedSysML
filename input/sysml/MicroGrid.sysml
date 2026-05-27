package MicroGridTwin {
    private import MetaModelDigitalTwin::*;

    #Component def PAC_Sensor {}

    #Entity def Charger {
        #constAttribute maxConsumption {
            :>> value default "50.0";
            :>> dataType default AttributeDataType::DOUBLE;
        }
        #component sensor : PAC_Sensor;
    }

    #Condition def StopCharging {
        #strategyAction stopCharging :>> strategieActions {
            :>> name = "stopCharging";
            :>> strategyType = StrategyType::LAMBDA;
            :>> pathToCode =
                "/home/marcocotrotzo/PycharmProjects/SymlCOnv/testLambdaFunctions/microgrid/stopCharging";
            :>> external = false;
        }
    }

    #Condition def HighConsumption {
        #strategyAction highConsumption :>> strategieActions {
            :>> name = "highConsumption";
            :>> strategyType = StrategyType::LAMBDA;
            :>> pathToCode =
                "/home/marcocotrotzo/PycharmProjects/SymlCOnv/testLambdaFunctions/microgrid/highConsumption";
            :>> external = false;
        }
    }

    #Condition def OverloadAlert {
        #strategyAction overloadAlert :>> strategieActions {
            :>> name = "overloadAlert";
            :>> strategyType = StrategyType::LAMBDA;
            :>> pathToCode =
                "/home/marcocotrotzo/PycharmProjects/SymlCOnv/testLambdaFunctions/microgrid/overloadAlert";
            :>> external = false;
        }
    }

    #Twin def MicroGrid {
        #entity Dummy {
            #entity MicroGrid {
                #entity KebaP30 : Charger {
                    :>> maxConsumption {
                        :>> value default "15.0";
                    }
                    p13 :>> sensor {
                        #measureAttribute power {
                            :>> dataType default AttributeDataType::DOUBLE;
                        }
                    }
                }
            }
        }
    }

    #Twin def MicroGrid2 {
        #entity MicroGrid {
            #entity KebaP30 : Charger {
                :>> maxConsumption {
                    :>> value default "15.0";
                }
                p13 :>> sensor {
                    #measureAttribute power {
                        :>> dataType default AttributeDataType::DOUBLE;
                    }
                }
            }
        }
    }
} 

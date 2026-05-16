package MicroGridTwin {

    private import MetaModelDigitalTwin::*;

    #Component def PAC_Sensor {
        
    }

    #Entity def Charger {
        #constAttribute maxConsumption {
            :>> value default "50.0";
            :>> dataType default AttributeDataType::DOUBLE;
        }
        #component sensor: PAC_Sensor;
    }

    #Condition def StopCharging {
        #strategyAction stopCharging :>> strategieActions {
            :>> name = "stopCharging";
            :>> strategyType = StrategyType::LAMBDA;
            :>> pathToCode = "/home/marcocotrotzo/PycharmProjects/SymlCOnv/testLambdaFunctions/microgrid/stopCharging";
            :>> external = false;
        }
    }

    #Condition def HighConsumption {
        #strategyAction highConsumption :>> strategieActions {
            :>> name = "highConsumption";
            :>> strategyType = StrategyType::LAMBDA;
            :>> pathToCode = "/home/marcocotrotzo/PycharmProjects/SymlCOnv/testLambdaFunctions/microgrid/highConsumption";
            :>> external = false;
        }
    }

    #Condition def OverloadAlert {
        #strategyAction overloadAlert :>> strategieActions {
            :>> name = "overloadAlert";
            :>> strategyType = StrategyType::LAMBDA;
            :>> pathToCode = "/home/marcocotrotzo/PycharmProjects/SymlCOnv/testLambdaFunctions/microgrid/overloadAlert";
            :>> external = false;
        }
    }

    #Twin def MicroGrid {
        #entity MicroGrid{
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
            #entity SieVersicharge : Charger {
                :>> maxConsumption {
                    :>> value default "50.0";
                }
                p14 :>> sensor {
                    #measureAttribute consumption {
                        :>> dataType default AttributeDataType::DOUBLE;
                    }
                }
            }
            #entity SieChargeCC : Charger {
                :>> maxConsumption {
                    :>> value default "50.0";
                }
                p12 :>> sensor {
                    #measureAttribute consumption {
                        :>> dataType default AttributeDataType::DOUBLE;
                    }
                }
            }
        }}

        :>> hotDatabaseRetentionDays default 30;
        :>> coldDatabaseRetentionDays default 30;

        #condition stopCharging : StopCharging {
            :>> leftOperand = MicroGrid.MicroGrid.KebaP30.p13.power;
            :>> operator = ComparisonOperator::EQUAL;
            :>> rightOperand = MicroGrid.MicroGrid.KebaP30.maxConsumption;
            :>> stopCharging {
                :>> feedbackTopicType = FeedbackTopicType::INTERN;
                :>> componentTopic = MicroGrid.MicroGrid.KebaP30.p13;
            }
        }

        #condition highConsumption : HighConsumption {
            :>> leftOperand = MicroGrid.MicroGrid.SieVersicharge.p14.consumption;
            :>> operator = ComparisonOperator::GREATER_THAN;
            :>> rightOperand = MicroGrid.MicroGrid.SieVersicharge.maxConsumption;
            :>> highConsumption {
                :>> feedbackTopicType = FeedbackTopicType::INTERN;
                :>> componentTopic = MicroGrid.MicroGrid.SieVersicharge.p14;
            }
        }

        #condition overloadAlert : OverloadAlert {
            :>> leftOperand = MicroGrid.MicroGrid.SieChargeCC.p12.consumption;
            :>> operator = ComparisonOperator::GREATER_THAN;
            :>> rightOperand = MicroGrid.MicroGrid.SieChargeCC.maxConsumption;
            :>> overloadAlert {
                :>> feedbackTopicType = FeedbackTopicType::INTERN;
                :>> componentTopic = MicroGrid.MicroGrid.SieChargeCC.p12;
                test1 :>> inputParameters = MicroGrid.MicroGrid.SieChargeCC.p12.consumption;
                :>> inputParameters = MicroGrid.MicroGrid.SieChargeCC.maxConsumption;
                test2 :>> inputParameters = MicroGrid.MicroGrid.KebaP30.p13.power;
                test3 :>> outputParameters = AttributeDataType::STRING;
                test6 :>> outputParameters = AttributeDataType::DOUBLE;
            }
        }
    }
}

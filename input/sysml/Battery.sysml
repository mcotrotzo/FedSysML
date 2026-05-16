package BatteryTwin {

    private import MetaModelDigitalTwin::*;

    #Component def PAC_Sensor {
        
    }

    #Condition def LowCapacity {
        #strategyAction lowCapacity :>> strategieActions {
            :>> name = "lowCapacity";
            :>> strategyType = StrategyType::LAMBDA;
            :>> pathToCode = "/home/marcocotrotzo/PycharmProjects/SymlCOnv/testLambdaFunctions/battery/low_capacity";
            :>> external = false;
        }
    }

    #Condition def FullyCharged {
        #strategyAction fullyCharged :>> strategieActions {
            :>> name = "fullyCharged";
            :>> strategyType = StrategyType::LAMBDA;
            :>> pathToCode = "/home/marcocotrotzo/PycharmProjects/SymlCOnv/testLambdaFunctions/battery/fully_charged";
            :>> external = false;
        }
    }

    #Condition def OverheatAlert {
        #strategyAction overheatAlert :>> strategieActions {
            :>> name = "overheatAlert";
            :>> strategyType = StrategyType::LAMBDA;
            :>> pathToCode = "/home/marcocotrotzo/PycharmProjects/SymlCOnv/testLambdaFunctions/battery/overheatAlert";
            :>> external = false;
        }
    }

    #Twin def Battery {
        #entity Battery{
            #entity Battery {
            #constAttribute totalCapacity {
                :>> value default "100.0";
                :>> dataType default AttributeDataType::DOUBLE;
            }
            #constAttribute minCapacity {
                :>> value default "10.0";
                :>> dataType default AttributeDataType::DOUBLE;
            }
            #constAttribute maxTemperature {
                :>> value default "45.0";
                :>> dataType default AttributeDataType::DOUBLE;
            }
            #component p16 : PAC_Sensor {
                #measureAttribute currentCapacity {
                    :>> dataType default AttributeDataType::DOUBLE;
                }
                #measureAttribute temperature {
                    :>> dataType default AttributeDataType::DOUBLE;
                }
            }
        }
    }
        :>> hotDatabaseRetentionDays default 30;
        :>> coldDatabaseRetentionDays default 30;

        #condition lowCapacity : LowCapacity {
            :>> leftOperand = Battery.Battery.p16.currentCapacity;
            :>> operator = ComparisonOperator::LESS_THAN;
            :>> rightOperand = Battery.Battery.minCapacity;
            :>> lowCapacity {
                :>> feedbackTopicType = FeedbackTopicType::INTERN;
                :>> componentTopic = Battery.Battery.p16;
            }
        }

        #condition fullyCharged : FullyCharged {
            :>> leftOperand = Battery.Battery.p16.currentCapacity;
            :>> operator = ComparisonOperator::EQUAL;
            :>> rightOperand = Battery.Battery.totalCapacity;
            :>> fullyCharged {
                :>> feedbackTopicType = FeedbackTopicType::INTERN;
                :>> componentTopic = Battery.Battery.p16;
            }
        }

        #condition overheatAlert : OverheatAlert {
            :>> leftOperand = Battery.Battery.p16.temperature;
            :>> operator = ComparisonOperator::GREATER_THAN ;
            :>> rightOperand = Battery.Battery.maxTemperature;
            :>> overheatAlert {
                :>> feedbackTopicType = FeedbackTopicType::INTERN;
                :>> componentTopic = Battery.Battery.p16;
                test1 :>> inputParameters = Battery.Battery.p16.temperature;
                :>> inputParameters = Battery.Battery.maxTemperature;
                test2 :>> inputParameters = Battery.Battery.p16.currentCapacity;
                test3 :>> outputParameters = AttributeDataType::STRING;
                test6 :>> outputParameters = AttributeDataType::DOUBLE;
            

        }
    }

}
}
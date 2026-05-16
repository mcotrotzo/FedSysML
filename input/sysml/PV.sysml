package PVTwin {

    private import MetaModelDigitalTwin::*;

    #Component def PAC_Sensor {
        
    }

    #Condition def HighOutput {
        #strategyAction highOutput :>> strategieActions {
            :>> name = "highOutput";
            :>> strategyType = StrategyType::LAMBDA;
            :>> pathToCode = "/home/marcocotrotzo/PycharmProjects/SymlCOnv/testLambdaFunctions/pv/highOutput";
            :>> external = false;
        }
    }

    #Condition def LowOutput {
        #strategyAction lowOutput :>> strategieActions {
            :>> name = "lowOutput";
            :>> strategyType = StrategyType::LAMBDA;
            :>> pathToCode = "/home/marcocotrotzo/PycharmProjects/SymlCOnv/testLambdaFunctions/pv/lowOutput";
            :>> external = false;
        }
    }

    #Condition def PeakProduction {
        #strategyAction peakProduction :>> strategieActions {
            :>> name = "peakProduction";
            :>> strategyType = StrategyType::LAMBDA;
            :>> pathToCode = "/home/marcocotrotzo/PycharmProjects/SymlCOnv/testLambdaFunctions/pv/peakProduction";
            :>> external = false;
        }
    }

    #Twin def PV {

        
        #entity PV {
        #entity PV {
            #constAttribute maxOutput {
                :>> value default "10000.0";
                :>> dataType default AttributeDataType::DOUBLE;
            }
            #constAttribute minOutput {
                :>> value default "100.0";
                :>> dataType default AttributeDataType::DOUBLE;
            }
            #constAttribute peakThreshold {
                :>> value default "8000.0";
                :>> dataType default AttributeDataType::DOUBLE;
            }
            #component pV1 :PAC_Sensor{
                #measureAttribute output {
                    :>> dataType default AttributeDataType::DOUBLE;
                }
            }
        }

        :>> hotDatabaseRetentionDays default 30;
        :>> coldDatabaseRetentionDays default 30;

        #condition highOutput : HighOutput {
            :>> leftOperand = PV.pV1.output;
            :>> operator = ComparisonOperator::GREATER_THAN;
            :>> rightOperand = PV.maxOutput;
            :>> highOutput {
                :>> feedbackTopicType = FeedbackTopicType::INTERN;
                :>> componentTopic = PV.pV1;
            }
        }
    }
    
        #condition lowOutput : LowOutput {
            :>> leftOperand = PV.PV.pV1.output;
            :>> operator = ComparisonOperator::LESS_THAN;
            :>> rightOperand = PV.PV.minOutput;
            :>> lowOutput {
                :>> feedbackTopicType = FeedbackTopicType::INTERN;
                :>> componentTopic = PV.PV.pV1;
            }
        }

        #condition peakProduction : PeakProduction {
            :>> leftOperand = PV.PV.pV1.output;
            :>> operator = ComparisonOperator::GREATER_THAN;
            :>> rightOperand = PV.PV.peakThreshold;
            :>> peakProduction {
                :>> feedbackTopicType = FeedbackTopicType::INTERN;
                :>> componentTopic = PV.PV.pV1;
                test1 :>> inputParameters = PV.PV.pV1.output;
                test2 :>> inputParameters = PV.PV.peakThreshold;
                test3 :>> outputParameters = AttributeDataType::STRING;
                test4 :>> outputParameters = AttributeDataType::DOUBLE;
            }
        }
    }
}

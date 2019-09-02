from qgis.core import QgsProcessing
from qgis.core import QgsProcessingAlgorithm
from qgis.core import QgsProcessingMultiStepFeedback
from qgis.core import QgsProcessingParameterVectorLayer
from qgis.core import QgsProcessingParameterFeatureSink
import processing


class AlternativaAUnione(QgsProcessingAlgorithm):

    def initAlgorithm(self, config=None):
        self.addParameter(QgsProcessingParameterVectorLayer('poligonidellaisocrona', 'Poligoni della isocrona', types=[QgsProcessing.TypeVectorPolygon], defaultValue=None))
        self.addParameter(QgsProcessingParameterFeatureSink('Computo', 'computo', type=QgsProcessing.TypeVectorAnyGeometry, createByDefault=True, defaultValue=None))

    def processAlgorithm(self, parameters, context, model_feedback):
        # Use a multi-step feedback, so that individual child algorithm progress reports are adjusted for the
        # overall progress through the model
        feedback = QgsProcessingMultiStepFeedback(8, model_feedback)
        results = {}
        outputs = {}

        # Da poligoni a linee
        alg_params = {
            'INPUT': parameters['poligonidellaisocrona'],
            'OUTPUT': QgsProcessing.TEMPORARY_OUTPUT
        }
        outputs['DaPoligoniALinee'] = processing.run('native:polygonstolines', alg_params, context=context, feedback=feedback, is_child_algorithm=True)

        feedback.setCurrentStep(1)
        if feedback.isCanceled():
            return {}

        # Poligonizza
        alg_params = {
            'INPUT': outputs['DaPoligoniALinee']['OUTPUT'],
            'KEEP_FIELDS': False,
            'OUTPUT': QgsProcessing.TEMPORARY_OUTPUT
        }
        outputs['Poligonizza'] = processing.run('qgis:polygonize', alg_params, context=context, feedback=feedback, is_child_algorithm=True)

        feedback.setCurrentStep(2)
        if feedback.isCanceled():
            return {}

        # Unione
        alg_params = {
            'INPUT': parameters['poligonidellaisocrona'],
            'OVERLAY': outputs['Poligonizza']['OUTPUT'],
            'OVERLAY_FIELDS_PREFIX': '',
            'OUTPUT': QgsProcessing.TEMPORARY_OUTPUT
        }
        outputs['Unione'] = processing.run('native:union', alg_params, context=context, feedback=feedback, is_child_algorithm=True)

        feedback.setCurrentStep(3)
        if feedback.isCanceled():
            return {}

        # Estrai tramite espressione
        alg_params = {
            'EXPRESSION': '$area > 1.0',
            'INPUT': outputs['Unione']['OUTPUT'],
            'OUTPUT': QgsProcessing.TEMPORARY_OUTPUT
        }
        outputs['EstraiTramiteEspressione'] = processing.run('native:extractbyexpression', alg_params, context=context, feedback=feedback, is_child_algorithm=True)

        feedback.setCurrentStep(4)
        if feedback.isCanceled():
            return {}

        # Calcolatore campi nro
        alg_params = {
            'FIELD_LENGTH': 9,
            'FIELD_NAME': 'nro',
            'FIELD_PRECISION': 0,
            'FIELD_TYPE': 1,
            'FORMULA': 'count(expression:=\"ID\" ,group_by:= format_number( $area,2))',
            'INPUT': outputs['EstraiTramiteEspressione']['OUTPUT'],
            'NEW_FIELD': True,
            'OUTPUT': QgsProcessing.TEMPORARY_OUTPUT
        }
        outputs['CalcolatoreCampiNro'] = processing.run('qgis:fieldcalculator', alg_params, context=context, feedback=feedback, is_child_algorithm=True)

        feedback.setCurrentStep(5)
        if feedback.isCanceled():
            return {}

        # Calcolatore campi ids
        alg_params = {
            'FIELD_LENGTH': 100,
            'FIELD_NAME': 'ids',
            'FIELD_PRECISION': 0,
            'FIELD_TYPE': 2,
            'FORMULA': 'replace(                              -- elimino la prima parte degli ID tp_\r\nconcatenate(                      -- concateno il risultato\r\nexpression:=\"ID\",               -- ID isolinee\r\ngroup_by:=format_number($area, 2),              -- raggruppo per superficie\r\nconcatenator:=\',\'), \'tp_\',\'\'\r\n)',
            'INPUT': outputs['CalcolatoreCampiNro']['OUTPUT'],
            'NEW_FIELD': True,
            'OUTPUT': QgsProcessing.TEMPORARY_OUTPUT
        }
        outputs['CalcolatoreCampiIds'] = processing.run('qgis:fieldcalculator', alg_params, context=context, feedback=feedback, is_child_algorithm=True)

        feedback.setCurrentStep(6)
        if feedback.isCanceled():
            return {}

        # Dissolvi
        alg_params = {
            'FIELD': 'ids',
            'INPUT': outputs['CalcolatoreCampiIds']['OUTPUT'],
            'OUTPUT': QgsProcessing.TEMPORARY_OUTPUT
        }
        outputs['Dissolvi'] = processing.run('native:dissolve', alg_params, context=context, feedback=feedback, is_child_algorithm=True)

        feedback.setCurrentStep(7)
        if feedback.isCanceled():
            return {}

        # Elimina campo(i)
        alg_params = {
            'COLUMN': 'ID',
            'INPUT': outputs['Dissolvi']['OUTPUT'],
            'OUTPUT': parameters['Computo']
        }
        outputs['EliminaCampoi'] = processing.run('qgis:deletecolumn', alg_params, context=context, feedback=feedback, is_child_algorithm=True)
        results['Computo'] = outputs['EliminaCampoi']['OUTPUT']
        return results

    def name(self):
        return 'alternativa a Unione'

    def displayName(self):
        return 'alternativa a Unione'

    def group(self):
        return 'fontanelle'

    def groupId(self):
        return 'fontanelle'

    def createInstance(self):
        return AlternativaAUnione()

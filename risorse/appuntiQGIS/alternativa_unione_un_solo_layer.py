from qgis.core import QgsProcessing
from qgis.core import QgsProcessingAlgorithm
from qgis.core import QgsProcessingMultiStepFeedback
from qgis.core import QgsProcessingParameterVectorLayer
from qgis.core import QgsProcessingParameterFeatureSink
import processing


class AlternativaAUnione(QgsProcessingAlgorithm):

    def initAlgorithm(self, config=None):
        self.addParameter(QgsProcessingParameterVectorLayer('poligonidellaisocrona', 'Poligoni della isocrona', types=[QgsProcessing.TypeVectorPolygon], defaultValue=None))
        self.addParameter(QgsProcessingParameterFeatureSink('Output', 'Output', type=QgsProcessing.TypeVectorAnyGeometry, createByDefault=True, defaultValue=None))

    def processAlgorithm(self, parameters, context, model_feedback):
        # Use a multi-step feedback, so that individual child algorithm progress reports are adjusted for the
        # overall progress through the model
        feedback = QgsProcessingMultiStepFeedback(3, model_feedback)
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
            'OUTPUT': parameters['Output']
        }
        outputs['Unione'] = processing.run('native:union', alg_params, context=context, feedback=feedback, is_child_algorithm=True)
        results['Output'] = outputs['Unione']['OUTPUT']
        return results

    def name(self):
        return 'alternativa a Unione'

    def displayName(self):
        return 'alternativa a Unione'

    def group(self):
        return 'fontanelle'

    def groupId(self):
        return ''

    def createInstance(self):
        return AlternativaAUnione()

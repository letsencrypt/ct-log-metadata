import base64
import subprocess


class CA:
    def __init__(self, pemData, origin):
        self._der = base64.b64decode(
            pemData.replace("\n", "")
            .replace("-----BEGIN CERTIFICATE-----", "")
            .replace("-----END CERTIFICATE-----", "")
            + "=="
        )
        self._origin = origin
        self._pem = None
        self._pubkey = None

    @property
    def pubkey(self):
        if not self._pubkey:
            self._pubkey = self._get_pubkey()
        return self._pubkey

    @property
    def origin(self):
        return self._origin

    @property
    def pem(self):
        if not self._pem:
            self._pem = self._get_pem()
        return self._pem

    @property
    def der(self):
        return self._der

    def _get_pubkey(self):
        try:
            result = subprocess.run(
                ["openssl", "x509", "-inform", "der", "-pubkey", "-noout"],
                capture_output=True,
                input=self.der,
            )
            if result.stderr:
                raise Exception(result.stderr.rstrip())
            return result.stdout.decode("UTF-8")

        except Exception as e:
            raise Exception("Couldn't get Public Key for pem %s" % (self.pem), e)

    def _get_pem(self):
        try:
            result = subprocess.run(
                ["openssl", "x509", "-inform", "der"],
                capture_output=True,
                input=self.der,
            )
            if result.stderr:
                raise Exception(result.stderr.rstrip())
            return result.stdout.decode("UTF-8")

        except Exception as e:
            raise Exception("Couldn't get PEM for %s" % (self.pem), e)

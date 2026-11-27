#!/usr/bin/env python3
"""Synchronise la collection Firestore `Troncons` avec assets/data/troncons_backup.json.

Le fichier JSON est la référence. Par défaut le script n'écrit rien : il affiche
les documents qu'il créerait ou modifierait. Ajouter --apply pour écrire.

    python3 tool/sync_firestore.py                 # aperçu
    python3 tool/sync_firestore.py --apply         # écriture
    python3 tool/sync_firestore.py --apply --token "$(gcloud auth print-access-token)"

Sans --token, le script utilise la clé API de google-services.json : l'écriture
ne fonctionne alors que si les règles Firestore l'autorisent sans connexion.
Les documents présents dans Firestore mais absents du JSON sont seulement
signalés, jamais supprimés.
"""

import argparse
import json
import sys
import urllib.error
import urllib.request
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
COLLECTION = 'Troncons'


def valeur_firestore(valeur):
    if isinstance(valeur, bool):
        return {'booleanValue': valeur}
    if isinstance(valeur, int):
        return {'integerValue': str(valeur)}
    if isinstance(valeur, float):
        return {'doubleValue': valeur}
    if isinstance(valeur, str):
        return {'stringValue': valeur}
    if isinstance(valeur, dict):
        return {'mapValue': {'fields': {k: valeur_firestore(v) for k, v in valeur.items()}}}
    if isinstance(valeur, list):
        return {'arrayValue': {'values': [valeur_firestore(v) for v in valeur]}}
    raise TypeError(f'Type non géré : {type(valeur)}')


def valeur_python(champ):
    type_, val = next(iter(champ.items()))
    if type_ == 'mapValue':
        return {k: valeur_python(v) for k, v in val.get('fields', {}).items()}
    if type_ == 'arrayValue':
        return [valeur_python(v) for v in val.get('values', [])]
    if type_ == 'integerValue':
        return int(val)
    if type_ == 'doubleValue':
        return float(val)
    return val


def normaliser(document):
    """Rend deux documents comparables (les entiers et réels se valent)."""
    return json.loads(json.dumps(document, sort_keys=True), parse_int=float)


def requete(url, methode='GET', corps=None, token=None):
    entetes = {'Content-Type': 'application/json'}
    if token:
        entetes['Authorization'] = f'Bearer {token}'
    donnees = json.dumps(corps).encode() if corps is not None else None
    req = urllib.request.Request(url, data=donnees, method=methode, headers=entetes)
    with urllib.request.urlopen(req) as reponse:
        return json.load(reponse)


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('--apply', action='store_true', help='écrire dans Firestore')
    parser.add_argument('--token', help='jeton OAuth (gcloud auth print-access-token)')
    args = parser.parse_args()

    config = json.loads((RACINE / 'android/app/google-services.json').read_text())
    projet = config['project_info']['project_id']
    cle = config['client'][0]['api_key'][0]['current_key']
    base = f'https://firestore.googleapis.com/v1/projects/{projet}/databases/(default)/documents/{COLLECTION}'
    auth = '' if args.token else f'?key={cle}'

    existants, jeton_page = {}, None
    while True:
        url = f'{base}?pageSize=300' + (f'&pageToken={jeton_page}' if jeton_page else '')
        url += '' if args.token else f'&key={cle}'
        page = requete(url, token=args.token)
        for doc in page.get('documents', []):
            existants[doc['name'].rsplit('/', 1)[-1]] = {
                k: valeur_python(v) for k, v in doc['fields'].items()
            }
        jeton_page = page.get('nextPageToken')
        if not jeton_page:
            break

    troncons = json.loads((RACINE / 'assets/data/troncons_backup.json').read_text())
    a_creer, a_modifier = [], []
    for troncon in troncons:
        doc_id = troncon['id']
        contenu = {k: v for k, v in troncon.items() if k != 'id'}
        if doc_id not in existants:
            a_creer.append((doc_id, contenu))
        elif normaliser(existants[doc_id]) != normaliser(contenu):
            a_modifier.append((doc_id, contenu))

    inconnus = sorted(set(existants) - {t['id'] for t in troncons})

    def libelle(contenu):
        return f"{contenu['axe']} : {contenu['depart']['name']} → {contenu['arrivee']['name']}"

    print(f'Firestore : {len(existants)} documents ; JSON : {len(troncons)} tronçons')
    print(f'\nÀ créer ({len(a_creer)}) :')
    for doc_id, contenu in a_creer:
        print(f'  + {libelle(contenu)}  [{doc_id}]')
    print(f'\nÀ modifier ({len(a_modifier)}) :')
    for doc_id, contenu in a_modifier:
        avant = existants[doc_id]
        details = [
            cle_champ for cle_champ in contenu
            if normaliser(avant.get(cle_champ)) != normaliser(contenu[cle_champ])
        ]
        print(f"  ~ {libelle(contenu)}  [{doc_id}] champs : {', '.join(details)}")
    if inconnus:
        print(f'\nDans Firestore mais pas dans le JSON (laissés tels quels) : {", ".join(inconnus)}')

    if not args.apply:
        print('\nAperçu seulement. Relancer avec --apply pour écrire.')
        return

    for doc_id, contenu in a_creer + a_modifier:
        corps = {'fields': {k: valeur_firestore(v) for k, v in contenu.items()}}
        try:
            requete(f'{base}/{doc_id}{auth}', methode='PATCH', corps=corps, token=args.token)
        except urllib.error.HTTPError as erreur:
            print(f'Échec sur {doc_id} : {erreur.code} {erreur.read().decode()[:300]}')
            sys.exit(1)
        print(f'  écrit : {libelle(contenu)}')
    print('Synchronisation terminée.')


if __name__ == '__main__':
    main()

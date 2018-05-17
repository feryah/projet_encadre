#/usr/bin/perl

# Milena Chaîne - 2017-2018
# commande : perl BAO3_treetagger_milena.pl ./sortie_cordial/rubrique_treetagger.xml fichier_patrons.txt numéro_rubrique
# description : ce programme parcourt le fichier xml contenant des étiquettes treetagger et extrait des patrons morphosyntaxiques prédéfinis dans ce fichier
# son fonctionnement est similaire à celui du programme pour Cordial, l'extraction des POS/tokens se fait différemment en fonction de la structure de la ligne
# données : le fichier XML traité par Treetagger, un fichier txt contenant des patrons (sous forme de regexp) à rechercher par ligne
# résultat : un fichier txt (en UTF-8) contenant les patrons extraits dans le fichier (une occurrence par ligne)

#-----------------------------------------------------------
use utf8;
binmode STDOUT, ":utf8";

my $test="Syntaxe : perl BAO3_cordial_milena.pl ./sortie_cordial/rubrique_cordial_utf8.txt fichier_patrons.txt numéro_rubrique\n";

if (@ARGV!=3) {
  die $test;
}

open (TREETAGGER,"<:encoding(utf-8)", $ARGV[0]);
open (MOTIF,"<:encoding(utf-8)", $ARGV[1]);

# on récupère le numéro de rubrique
my $rubrique = $ARGV[2];

# on extrait la liste de motifs
@liste_motif = <MOTIF>;
print "Liste des motifs recherchés\n";
print @liste_motif;
print "\n";

close MOTIF;

#-----------------------------------------------------------
# transformation du fichier Treetagger en listes de tokens et de POS
my @liste_tokens=();
my @liste_POS=();

# pour chaque ligne du fichier
while (my $ligne = <TREETAGGER>) {
  #passer à la ligne suivante si la ligne n'est pas une ligne contenant un token
  next if ($ligne!~/^<element><data type="type">([^>]+)<\/data><data type="lemma">([^>]+)<\/data><data type="string">([^>]+)<\/data><\/element>/);
	my $pos = $1;
	my $token = $3;
  print "TOKEN : $token\tPOS : $pos\n";
  #rajouter le token (premier élément de la ligne/liste) à la liste globale
  #de même pour la POS
  push(@liste_tokens , $token);
  push(@liste_POS, $pos);
}

close CORDIAL;

#-----------------------------------------------------------
# on va créer un fichier différent
foreach $motif (@liste_motif) {
  chomp ($motif);
  print "MOTIF : $motif\n";
  mkdir $rubrique;
  open($sortie, ">>:encoding(utf-8)", "./$rubrique/TREETAGGER_$motif.txt")
    || die "Impossible d'ouvrir $motif.txt";

  # transformer le motif en une liste de POS et vérifier le nombre de POS qu'il contient
  my @patron = split(/\#/, $motif);
  my $longueur_patron = scalar @patron;
  my $longueur_liste = scalar @liste_tokens;
  my $sequence = "";
  my $indice_liste = 0;
  my $indice_motif = 0;
  my $decalage = 0;

  # on va passer par chaque ligne/POS de notre fichier
  while ($indice_liste < $longueur_liste) {
    if ($liste_POS[$indice_liste] =~ /$patron[$indice_motif]/) {
      #on garde en mémoire où on en est dans la liste
      $decalage = $indice_liste;
      #on commence à composer le motif
      $sequence = $sequence.$liste_tokens[$indice_liste];

      # tant qu'il reste des POS à trouver pour compléter le patron
      while ($indice_motif < ($longueur_patron-1)) {
        $indice_liste++;
        $indice_motif++;
        # on cherche la POS suivante
        if ($liste_POS[$indice_liste] =~ /$patron[$indice_motif]/) {
          $sequence = $sequence." ".$liste_tokens[$indice_liste];
        }
        # si elle ne correspond pas au patron on sort et on se remet à zéro
        else {
          $decalage++;
          $indice_liste = $decalage;
          $sequence = "";
          $indice_motif = 0;
          last;
        }
      }

      # si on a complété un patron on l'imprime
      if ($sequence) {
        print "MOTIF TROUVE : $sequence\n";
        print $sortie "$sequence\n";
      }
      # on se remet à zéro
      $sequence = "";
      $indice_motif = 0;
      $decalage++;
      $indice_liste = $decalage;
    }
    # si la ligne qu'on traite ne correspond pas au début du motif on enchaîne
    else {
      $indice_liste++;
    }
  }
}

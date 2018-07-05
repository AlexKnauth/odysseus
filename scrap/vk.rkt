#lang racket

(require "../lib/load/all.rkt")
(require "../../settings/APIs.rkt")
(require net/url)
(require json)
(require browser/external)
(require compatibility/defmacro)

(define status-output (make-parameter #f))
(define friends-limit (make-parameter #f))

(define CID ($ id vk/odysseus))
(define AT ($ access_token vk/odysseus))

(provide (all-defined-out))

; gets a new access_token if old is expired
; after launching this function it opens the browser, where you should accept the app permissions and then, on the redirected page, check access_token in the GET parameters in the browser address string
(define (authenticate-through-browser)
  (let* ((auth-url "https://oauth.vk.com/authorize")
        (redirect_uri "")
        (display "page")
        (scope #b111111011110111011111)
        (response_type "token")
        (v "5.8")
        (state "odysseus")
        (request-string (url-with-parameters auth-url CID redirect_uri display scope response_type v state)))
    (send-url request-string)))
    ; (json->hash (get-url request-string))))

(define-catch (dump-ids-to-file ids)
  (let ((comma-separated-ids (implode ids ",")))
    (write-file "ids.txt" comma-separated-ids)))

(define-catch (read-ids-from-file filename)
  (let ((ids-string (read-file filename)))
    (split ids-string ",")))

;;;;; User ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define special-values (list "<user-deactivated>"))

(define user-basic-fields '(first_name last_name deactivated hidden))
(define user-optional-fields-all '(
                                about activities
                                bdate blacklisted blacklisted_by_me books
                                can_post can_see_all_post can_write_private_message career city common_count connections contacts counters country crop_photo
                                domain
                                education exports
                                first_name_nom first_name_gen first_name_dat first_name_acc first_name_ins first_name_abl
                                followers_count friend_status
                                games
                                has_mobile has_photo home_town
                                interests is_favorite is_friend is_hidden_from_feed
                                last_name_nom last_name_gen last_name_dat last_name_acc last_name_ins last_name_abl
                                last_seen lists
                                maiden_name military movies music
                                nickname
                                occupation online
                                personal
                                photo_id photo_max photo_max_orig photo_50 photo_100 photo_200_orig photo_400_orig
                                quotes
                                relatives relation
                                schools screen_name sex site status
                                timezone trending tv
                                universities
                                verified
                                wall_default
                              ))
(define personal-object-fields '(political langs religion inspired_by people_main life_main smoking alcohol))
(define schools-array-fields '(id country city name year_from year_to year_graduated class speciality type type_str))
(define universities-array-fields '(id country city name faculty faculty_name chair chair_name graduation education_form education_status))

(define user-basic-fields-used '(first_name last_name))
(define user-optional-fields-used
                              '(
                                bdate
                                ; blacklisted blacklisted_by_me
                                books
                                ;can_post can_see_all_post can_write_private_message
                                career city common_count connections contacts counters country
                                ; crop_photo
                                domain
                                education exports
                                ; first_name_nom first_name_gen first_name_dat first_name_acc first_name_ins first_name_abl
                                followers_count friend_status
                                games
                                has_mobile has_photo home_town
                                interests is_favorite is_friend is_hidden_from_feed
                                ; last_name_nom last_name_gen last_name_dat last_name_acc last_name_ins last_name_abl
                                last_seen lists
                                maiden_name military movies music
                                nickname
                                occupation online
                                personal
                                ; photo_id
                                photo_max
                                ; photo_max_orig photo_50 photo_100 photo_200_orig photo_400_orig
                                quotes
                                relatives relation
                                schools screen_name sex site status
                                timezone trending tv
                                universities
                                verified
                                wall_default
                              ))

(define user-fields (append user-basic-fields-used user-optional-fields-used))

(define-catch (get-user-info user-id #:fields (fields user-fields) #:status (status #f) #:access-token (access-token #f))
  (when status (display status) (flush-output))
  (let* (
        (fields (implode fields ","))
        (request (format "https://api.vk.com/method/users.get?user_ids=~a&fields=~a&v=5.52" user-id fields))
        (access_token (@. vk/odysseus.access_token)) ; comment this line if you need get-user-info function to be more universal
        (request (if access_token (format "~a&access_token=~a" request access_token) request))
        (res (json->hash (get-url request))))
        ; (res (hash)))
    (if (@. res.error)
        (hash 'error (@. res.error))
        (car (@. res.response)))))

(define-catch (get-friends-of-user user-id #:status (status #f) #:friends-limit (friends-limit #f))
  (when status (display status) (flush-output))
  (let ((res (string->jsexpr
                    (get-url (format "https://api.vk.com/method/friends.get?user_id=~a&v=5.52" user-id)))))
    (cond
      ((@. res.error)
        (list "<user-deactivated>"))
      (else
        (let ((items (@. res.response.items)))
          (if (and friends-limit (> (length items) friends-limit))
            (take items friends-limit)
            items))))))

(define-catch (output-user-file filename)
  (let ((users (read-serialized-data-from-file filename)))
    (for ((user (hash-values users)))
      (when (and ($ first_name user) ($ last_name user) (not (equal? ($ first_name user) "DELETED")))
        (display (format "~a ~a,~a,~a  ~a~n"
                      (or ($ first_name user) "")
                      (or ($ last_name user) "")
                      (or ($ bdate user) "")
                      (or
                        ($ city.title user) ($ home_town user)
                        "")
                      (let ((status ($ status user)))
                        (if (no-words? status) "" (str "[" (string-replace status "\n" "") "]")))
                      ))))))

(define-catch (number-of-users filename)
  (let ((users (read-serialized-data-from-file filename)))
    (--- (length (hash-keys users)))))

;;; Groups ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define (get-group-name groupid)
  (let ((res (string->jsexpr
                    (get-url (format "https://api.vk.com/method/groups.getById?group_id=~a&v=5.52&access_token=~a" groupid AT)))))
    (if (@. res.error)
      null
      (hash-ref (car (hash-ref res 'response)) 'name))))

(define (raw-community? type)
  (λ (groupid)
    (regexp-match (pregexp (str (symbol->string type) "\\d+")) groupid)))

(define raw-group? (raw-community? 'club))
(define raw-public? (raw-community? 'public))
(define raw-event? (raw-community? 'event))

(define (extract-pure-id groupid)
  (cond
    ((raw-group? groupid) (ltrim groupid (len "club")))
    ((raw-public? groupid) (ltrim groupid (len "public")))
    ((raw-event? groupid) (ltrim groupid (len "event")))
    (else groupid)))

(define (get-group-users groupid)
  (when (status-output) (display (format "~a~n" groupid)) (flush-output))
  (let* ( (groupid (extract-pure-id groupid))
          (res (string->jsexpr
                    (get-url (format "https://api.vk.com/method/groups.getMembers?group_id=~a&v=5.52" groupid)))))
    (if (@. res.error)
      null
      (map str (@. res.response.items)))))

(define (vk/intersect-groups . groups)
  (when (status-output) (display "\nscanning groups: \n"))
  (apply set-intersect (map get-group-users groups)))

(define (vk/minus-groups . groups)
  (when (status-output) (display "\nscanning groups: \n"))
  (apply minus (map get-group-users groups)))

(define (vk/difference-groups . groups)
  (when (status-output) (display "\nscanning groups: \n"))
  (apply difference (map get-group-users groups)))

; for expressions in the command line:
(define-macro (g-op op)
  `(λ groups
    (let
      ((uids-by-groups
          (map
            (λ (group)
              (cond
                ((list? group) group)
                ((string? group) (get-group-users group))
                (else group)))
            groups)))
      (apply ,op uids-by-groups))))

(define g^ (g-op set-intersect))
(define g- (g-op minus))
(define g-- (g-op difference))

;;; Group wall ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (get-wall-posts gid #:offset (offset #f) #:limit (limit #f))
  (let* ((reqstr (format "https://api.vk.com/method/wall.get?owner_id=-~a&v=5.8&filter=others&~a~a&access_token=~a"
                    gid
                    (if offset (str "&offset=" offset) "")
                    (if limit (str "&count=" limit) "")
                    AT))
        (res (string->jsexpr
                    (get-url reqstr)))
        (response ($ response res))
        ; (_ (--- "get-wall-posts: reqstr =" reqstr "count = "  ($ count response) "items-length = " (length ($ items response))))
        (err ($ error res)))
    (if err
      (error err)
      response)))